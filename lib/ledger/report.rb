module Ledger
  # Class responsible for doing the correct calculations to generate reports
  # about the income/expenses of the account.
  class Report
    attr_reader :account, :filtered_transactions, :currency, :total_transactions, :monthly_transactions

    def initialize(account, filtered_transactions, total_transactions, month, currency = nil)
      @account = account
      @currency = currency || filtered_transactions.first.currency
      @filtered_transactions = filtered_transactions.map { |t| t.exchange_to(@currency) }
      @total_transactions = total_transactions.map { |t| t.exchange_to(@currency) }
      @monthly_transactions = @total_transactions.select { |t| t.parsed_date.month == month }
    end

    def categories
      list = filtered_transactions.group_by(&:category).map do |category, cts|
        [category].concat(MoneyHelper.balance(cts, filtered_transactions))
      end

      list.sort_by { |l| l[2].is_a?(String) ? -1 : l[2] }.reverse
    end

    def total
      ['Total'].concat(MoneyHelper.balance(filtered_transactions))
    end

    def monthly
      money_values = MoneyHelper.balance(monthly_transactions, []) do |value|
        income = monthly_transactions.reject(&:expense?).sum(&:money)
        expense = monthly_transactions.select(&:expense?).sum(&:money)

        value.negative? ? [value, income] : [income - expense.abs, total_transactions.sum(&:money)]
      end

      ['Monthly'].concat(money_values)
    end
  end
end
