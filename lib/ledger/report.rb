# Class responsible for doing the correct calculations to generate reports
# about the income/expenses of the account.
class Report
  include CommandLineReporter

  TITLE = {width: 70, align: 'center', rule: true, color: :cyan, bold: true}.freeze
  HEADER = {
    summary: %w[Category Outflow (%) Inflow (%)],
    detailed: %w[Date Category Amount (%)]
  }.freeze
  HEADER_OPTIONS = {
    summary: [
      {width: 20},
      {width: 15, align: 'center'}, {width: 7, align: 'center'},
      {width: 15, align: 'center'}, {width: 7, align: 'center'}
    ],
    detailed: [
      {width: 15}, {width: 20},
      {width: 15, align: 'center'}, {width: 7, align: 'center'}
    ]
  }.freeze

  attr_reader :account, :filtered_transactions, :currency, :total_transactions, :monthly_transactions

  def initialize(account, filtered_transactions, total_transactions, month)
    @account = account
    @filtered_transactions = filtered_transactions
    @currency = filtered_transactions.first.currency
    @total_transactions = total_transactions.map { |t| t.dup.tap { |tt| tt.money = t.money.exchange_to(currency) } }
    @monthly_transactions = @total_transactions.select { |t| t.parsed_date.month == month }
  end

  def display(detailed)
    detailed ? details : summary
  end

  private

  def details
    title
    table do
      main_header(:detailed)

      transactions_details.each { |values| add_row(values, color: values.pop ? :white : :black) }

      footer { |value| value[0..2].unshift('') }
    end
  end

  def summary
    title
    table do
      main_header(:summary)

      categories.each { |values| add_row(values, color: :white) }

      footer
    end
  end

  def title
    header(TITLE.merge(title: account))
  end

  def main_header(type)
    add_row(HEADER[type], HEADER_OPTIONS[type], color: :blue, bold: true)
  end

  def footer
    total = block_given? ? yield(total_filtered) : total_filtered
    month = block_given? ? yield(monthly) : monthly

    add_row(total, color: :yellow)
    add_row(month, color: :magenta)
  end

  def add_row(list, column_options = [], **row_options)
    row(row_options) do
      list.each_with_index { |v, i| column(v, column_options.fetch(i, {})) }
    end
  end

  def transactions_details
    filtered_transactions.map do |transaction|
      money = MoneyHelper.display(transaction.money)
      percentage = percentage(transaction.money)
      processed = transaction.processed_value

      [transaction.date, transaction.category, money, percentage, processed]
    end
  end

  def categories
    filtered_transactions.group_by(&:category).map do |category, cts|
      [category].concat(balance(cts))
    end
  end

  def total_filtered
    ['Total'].concat(balance(filtered_transactions))
  end

  def monthly
    money_values = balance(monthly_transactions) do |value|
      income = monthly_transactions.reject(&:expense?).sum(&:money)
      expense = monthly_transactions.select(&:expense?).sum(&:money)

      value.negative? ? [value, income] : [income - expense.abs, total_transactions.sum(&:money)]
    end

    ['Monthly'].concat(money_values)
  end

  def balance(transactions, &block)
    [
      transactions.select(&:expense?).sum(&:money),
      transactions.reject(&:expense?).sum(&:money)
    ].map do |value|
      [MoneyHelper.display(value), percentage(value, &block)]
    end.flatten
  end

  def percentage(value, &block)
    value, total = percentage_values(value, &block)

    return '-' * 5 unless total.is_a?(Money) && value.is_a?(Money)

    ((value.abs / total.abs) * 100).to_f.round(2)
  end

  def percentage_values(value)
    return unless value.is_a?(Money)

    return yield(value) if block_given?

    filter = value.negative? ? :select : :reject
    [value, filtered_transactions.public_send(filter, &:expense?).sum(&:money)]
  end
end
