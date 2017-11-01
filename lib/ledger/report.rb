# Class responsible for doing the correct calculations to generate reports
# about the income/expenses of the account.
class Report
  include CommandLineReporter

  TITLE = {width: 70, align: 'center', rule: true, color: :cyan, bold: true}.freeze
  HEADER = %w[Category Outflow (%) Inflow (%)].freeze
  HEADER_OPTIONS = [
    {width: 20},
    {width: 15, align: 'center'}, {width: 7, align: 'center'},
    {width: 15, align: 'center'}, {width: 7, align: 'center'}
  ].freeze

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

  def details; end

  def summary
    header(TITLE.merge(title: account))
    table do
      add_row(HEADER, HEADER_OPTIONS, color: :blue, bold: true)
      categories.each { |values| add_row(values, color: :white) }
      add_row(total_filtered, color: :yellow)
      add_row(monthly, color: :magenta)
    end
  end

  def add_row(list, column_options = [], **row_options)
    row(row_options) do
      list.each_with_index { |v, i| column(v, column_options.fetch(i, {})) }
    end
  end

  def categories
    filtered_transactions.group_by(&:category).map do |category, cts|
      money_values = balance(cts) do |value|
        filter = value.negative? ? :select : :reject
        [value, filtered_transactions.public_send(filter, &:expense?).sum(&:money)]
      end

      [category].concat(money_values)
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
    ].map { |value| [MoneyHelper.display(value), percentage(value, &block)] }.flatten
  end

  def percentage(value)
    value, total = yield(value) if block_given? && value.is_a?(Money)

    return '-' * 5 unless total.is_a?(Money)

    ((value.abs / total.abs) * 100).to_f.round(2)
  end
end
