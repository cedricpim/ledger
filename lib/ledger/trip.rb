module Ledger
  # Class responsible for representing a trip, it contains the identifier of the
  # trip (travel attribute) and all the transactions belonging to this trip. It
  # is capable of listing the transactions and provide a summary of the
  # transactions, grouped by category.
  class Trip
    attr_reader :travel, :currency, :transactions, :monthly_income

    def initialize(travel, transactions, total_transactions, currency)
      @travel = travel
      @currency = currency
      @transactions = transactions.map { |t| t.exchange_to(currency) }
      @monthly_income = total_transactions.select(&:income?).map do |t|
        next unless t.parsed_date.month == transactions.last.parsed_date.month

        t.exchange_to(currency)
      end.compact
    end

    def categories
      list = transactions.group_by(&:category).map do |category, cts|
        money = cts.sum(&:money)
        percentage = MoneyHelper.percentage(money) { |value| [value, transactions.sum(&:money)] }

        [category].push(MoneyHelper.display(money), percentage)
      end

      list.sort_by(&:last).reverse
    end

    def total
      total_spent = transactions.sum(&:money)
      percentage = MoneyHelper.percentage(total_spent) { |value| [value, monthly_income.sum(&:money)] }

      ['Total'].push(MoneyHelper.display(total_spent), percentage)
    end
  end
end
