# Class responsible for doing the correct calculations to generate reports
# about the income/expenses of the account.
class Report
  attr_reader :account, :filtered_transactions, :currency, :total_transactions

  def initialize(account, filtered_transactions, total_transactions)
    @account = account
    @filtered_transactions = filtered_transactions
    @currency = filtered_transactions.first.currency
    @total_transactions = total_transactions
  end

  def title
    format(
      templates[:title],
      account: account,
      current: MoneyHelper.display(total_transactions.select { |t| t.account == account }.sum(&:money)),
      total_current: MoneyHelper.display(exchanged(total_transactions).sum(&:money))
    )
  end

  def monthly_balance
    monthly_transactions = total_transactions.select { |t| t.parsed_date.month == Date.today.month }

    format(templates[:monthly], money: money(exchanged(monthly_transactions)))
  end

  def to_s(options)
    options[:summary] ? summary : filtered_transactions
  end

  def footer
    format(templates[:totals], totals: money(filtered_transactions))
  end

  private

  def summary
    filtered_transactions.group_by(&:category).map do |category, cts|
      money = money(cts) do |value, formatted_value|
        next formatted_value if value.positive?

        format(templates[:expense], display: formatted_value, percentage: percentage_expense(value))
      end

      format(templates[:summary], category: category, money: money)
    end
  end

  def money(transactions)
    expense = transactions.select(&:expense?).sum(&:money)
    income = transactions.reject(&:expense?).sum(&:money)

    [expense, income].reject(&:zero?).map do |value|
      block_given? ? yield(value, MoneyHelper.display(value)) : MoneyHelper.display(value)
    end.join(' | ')
  end

  def percentage_expense(money)
    total_expense = filtered_transactions.select(&:expense?).sum(&:money)
    return 100.0 if total_expense.zero?

    ((money.abs / total_expense.abs) * 100).to_f.round(2)
  end

  def exchanged(transactions)
    transactions.map do |transaction|
      Transaction.new.tap { |t| t.money = transaction.money.exchange_to(currency) }
    end
  end

  def templates
    @templates ||= CONFIG.templates(:report)
  end
end
