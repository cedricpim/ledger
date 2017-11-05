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
      @transactions = transactions.map { |t| t.dup.tap { |tt| tt.money = t.money.exchange_to(currency) } }
      @monthly_income = total_transactions.map do |t|
        next unless t.parsed_date.month == transactions.last.parsed_date.month && t.income?

        t.dup.tap { |tt| tt.money = t.money.exchange_to(currency) }
      end.compact
    end

    def categories
      transactions.group_by(&:category).map do |category, cts|
        money = cts.sum(&:money)
        percentage = MoneyHelper.percentage(money) { |value| [value, transactions.sum(&:money)] }

        [category].push(MoneyHelper.display(money), percentage)
      end
    end

    def total(type)
      total_spent = transactions.sum(&:money)
      percentage = MoneyHelper.percentage(total_spent) { |value| [value, monthly_income.sum(&:money)] }

      label = type == :detailed ? ['', '', 'Total'] : ['Total']
      label.push(MoneyHelper.display(total_spent), percentage)
    end
  end
end
