# Each transaction belongs to a certain account. This class represents that
# entity, with a given name/code, the list of all its transactions and a
# currency (each account only have transactions on a single currency). It
# contains methods displaying balances and sums grouped by categories.
class Account
  attr_reader :name, :transactions, :currency

  def initialize(name, transactions)
    @name = name
    @transactions = transactions
    @currency = transactions.first.currency
  end

  def balance
    format(templates[:balance], money: MoneyHelper.balance(monthly_transactions))
  end

  def categories
    monthly_transactions.group_by(&:category).map do |category, cts|
      money = MoneyHelper.balance(cts) do |value, formatted_value|
        next formatted_value if value.positive?

        format(templates[:expense], display: formatted_value, percentage: percentage_expense(value))
      end

      format(templates[:summary], category: category, money: money)
    end
  end

  def current
    transactions.map(&:money).sum
  end

  private

  def percentage_expense(money)
    total_expense = monthly_transactions.select(&:expense?).sum(&:money)
    return 100.0 if total_expense.zero?

    ((money.abs / total_expense.abs) * 100).to_f.round(2)
  end

  def monthly_transactions
    @monthly_transactions ||= transactions.select do |transaction|
      transaction.parsed_date.month == Date.today.month
    end
  end

  def templates
    @templates ||= CONFIGS.dig(:format, :accounts)
  end
end
