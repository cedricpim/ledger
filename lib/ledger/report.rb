module Ledger
  # Class responsible for doing the correct calculations to generate reports
  # about the income/expenses of the account.
  class Report
    attr_reader :account, :filtered_transactions, :currency, :total_transactions, :period_transactions

    def initialize(account, filtered_transactions, total_transactions, period, currency = nil)
      @account = account
      @currency = currency || filtered_transactions.first.currency
      @filtered_transactions = filtered_transactions.map { |t| t.exchange_to(@currency) }
      @total_transactions = total_transactions.map { |t| t.exchange_to(@currency) }
      @period_transactions = @total_transactions.select { |t| t.parsed_date.between?(*period) }
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

    def period
      money_values = MoneyHelper.balance(period_transactions) do |value|
        income = period_transactions.reject(&:expense?).sum(&:money)
        expense = period_transactions.select(&:expense?).sum(&:money)

        value.negative? ? [value, income] : [income - expense.abs, total_transactions.sum(&:money)]
      end

      ['Period'].concat(money_values)
    end
  end
end
