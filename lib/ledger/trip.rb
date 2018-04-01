module Ledger
  # Class responsible for representing a trip, it contains the identifier of the
  # trip (travel attribute) and all the transactions belonging to this trip. It
  # is capable of listing the transactions and provide a summary of the
  # transactions, grouped by category.
  class Trip
    attr_reader :travel, :transactions, :total_transactions, :currency

    def initialize(travel, transactions, total_transactions, currency)
      @travel = travel
      @transactions = transactions.map { |t| t.exchange_to(currency) }
      @total_transactions = total_transactions
      @currency = currency
    end

    def date
      @date ||= transactions.sort_by(&:parsed_date).last.parsed_date
    end

    def categories
      list = transactions.group_by(&:category).map do |category, cts|
        money = cts.sum(&:money)

        [category, MoneyHelper.display(money), MoneyHelper.percentage(money, transactions)]
      end

      list.sort_by(&:last).reverse
    end

    def total
      total_spent = transactions.sum(&:money)

      percentage = MoneyHelper.percentage(total_spent) do
        total_transactions.select { |t| t.income? && t.parsed_date.month == date.month }.sum(&:money)
      end

      ['Total', MoneyHelper.display(total_spent), percentage]
    end
  end
end
