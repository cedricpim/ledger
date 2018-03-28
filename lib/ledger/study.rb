module Ledger
  # Class responsible for doing the correct calculations to generate studies
  # related to a category and about its income/expenses of the account.
  class Study
    attr_reader :account, :filtered_transactions, :currency, :total_transactions, :period_transactions

    def initialize(account, filtered_transactions, total_transactions, period, currency = nil)
      @account = account
      @currency = currency || filtered_transactions.first.currency
      @filtered_transactions = filtered_transactions.map { |t| t.exchange_to(@currency) }
      @total_transactions = total_transactions.map { |t| t.exchange_to(@currency) }
      @period_transactions = @total_transactions.select { |t| t.parsed_date.between?(*period) }
    end


    def descriptions
      list = filtered_transactions.group_by(&:description).map do |description, dts|
        money = dts.sum(&:money)
        [description, dts.count].concat([MoneyHelper.display(money), MoneyHelper.percentage(money, filtered_transactions)])
      end

      list.sort_by { |l| l[2].is_a?(String) ? -1 : l[2] }.reverse
    end

    def total
      money = filtered_transactions.sum(&:money)
      [
        filtered_transactions.first.category,
        filtered_transactions.count,
        MoneyHelper.display(money),
        MoneyHelper.percentage(money, period_transactions)
      ]
    end
  end
end
