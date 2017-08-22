# Class responsible for doing the correct calculations to generate reports
# about the income/expenses of the account.
class Report
  attr_reader :account, :transactions

  def initialize(account, transactions)
    @account = account
    @transactions = transactions
  end

  def total_text
    text('Total', transactions) { |expense| [expense.to_f, account.currency].join('') }
  end

  def to_s(options)
    options[:summary] ? summary : transactions
  end

  private

  def summary
    transactions.group_by(&:category).map do |category, cts|
      text(category.upcase, cts) { |expense| "#{expense.to_f}#{account.currency} (#{percentage(expense)}%)" }
    end
  end

  def text(category, transactions)
    expense = transactions.select(&:expense?).sum(&:amount)
    income = transactions.reject(&:expense?).sum(&:amount)
    expense_text = yield(expense) unless expense.zero?
    income_text = "+#{income.to_f}#{account.currency}" unless income.zero?
    "#{category.upcase}: #{[expense_text, income_text].compact.join(' | ')}"
  end

  def percentage(amount)
    total_expense = transactions.select(&:expense?).sum(&:amount)
    return 100.0 if total_expense.zero?

    ((amount.abs / total_expense.abs) * 100).to_f.round(2)
  end
end
