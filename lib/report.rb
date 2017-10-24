# Class responsible for doing the correct calculations to generate reports
# about the income/expenses of the account.
class Report
  attr_reader :account, :transactions

  def initialize(account, transactions)
    @account = account
    @transactions = transactions
  end

  def to_s(options)
    options[:summary] ? summary : transactions
  end

  def footer
    totals = money(transactions) { |_value, formatted_value| formatted_value }

    format(templates[:totals], totals: totals)
  end

  private

  def summary
    transactions.group_by(&:category).map do |category, cts|
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
      yield value, value.format(CONFIGS.dig(:format, :fields, :money, :display))
    end.join(' | ')
  end

  def percentage_expense(money)
    total_expense = transactions.select(&:expense?).sum(&:money)
    return 100.0 if total_expense.zero?

    ((money.abs / total_expense.abs) * 100).to_f.round(2)
  end

  def templates
    @templates ||= CONFIGS.dig(:format, :report)
  end
end
