module Ledger
  # Class responsible for doing the correct calculations to generate studies
  # related to a category and about its income/expenses of the account.
  class Study
    # Space reserved for displaying the amount of entries
    SPACE_FOR_UNITS = 6
    # Space used by characters that enclose each side of the amount
    ENCLOSING_UNIT = 1

    attr_reader :account, :transactions, :currency, :total_transactions, :period_transactions

    def initialize(account, transactions, total_transactions, period_transactions, currency)
      @account = account
      @currency = currency
      @transactions = transactions.map { |t| t.exchange_to(@currency) }
      @total_transactions = total_transactions.map { |t| t.exchange_to(@currency) }
      @period_transactions = period_transactions.map { |t| t.exchange_to(@currency) }
    end

    def list
      list = transactions.group_by(&:description).map do |description, dts|
        money = dts.sum(&:money)

        [
          padded_description(description, dts),
          MoneyHelper.display(money),
          MoneyHelper.percentage(money, transactions),
          MoneyHelper.percentage(money, period_transactions)
        ]
      end

      list.sort_by { |l| l[2] }.reverse
    end

    def total
      money = transactions.sum(&:money)
      [
        padded_description(transactions.first.category, transactions),
        MoneyHelper.display(money),
        MoneyHelper.percentage(money, period_transactions),
        MoneyHelper.percentage(money, total_transactions)
      ]
    end

    private

    def padded_description(value, transactions)
      whitespaces = SPACE_FOR_UNITS - 2 * ENCLOSING_UNIT - transactions.length.to_s.length
      "(#{transactions.count})#{' ' * whitespaces}#{value}"
    end
  end
end
