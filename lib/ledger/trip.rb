module Ledger
  # Class responsible for representing a trip, it contains the identifier of the
  # trip (travel attribute) and all the transactions belonging to this trip. It
  # is capable of listing the transactions and provide a summary of the
  # transactions, grouped by category.
  class Trip
    attr_reader :travel, :transactions, :total_transactions

    def initialize(travel, transactions, total_transactions)
      @travel = travel
      @transactions = transactions
      @total_transactions = total_transactions
    end

    def date
      @date ||= transactions.max_by(&:parsed_date).parsed_date
    end

    def list
      list = transactions.group_by(&:category).map do |category, cts|
        [category].concat(MoneyHelper.display_with_percentage(cts, transactions))
      end

      list.sort_by(&:last).reverse
    end

    def total
      monthly_income = total_transactions.select { |t| t.income? && t.parsed_date.month == date.month }.sum(&:money)
      ['Total'].concat(MoneyHelper.display_with_percentage(transactions) { monthly_income })
    end
  end
end
