module Ledger
  # Class responsible for doing the correct calculations to generate studies
  # related to a category and about its income/expenses of the account.
  class Analyse
    # Space reserved for displaying the amount of entries
    SPACE_FOR_UNITS = 6
    # Space used by characters that enclose each side of the amount
    ENCLOSING_UNIT = 1

    attr_reader :account, :transactions, :period_transactions, :total_transactions

    def initialize(account, transactions, period_transactions, total_transactions)
      @account = account
      @transactions = transactions
      @period_transactions = period_transactions
      @total_transactions = total_transactions
    end

    def list
      list = transactions.group_by(&:description).map do |description, dts|
        [padded_description(description, dts)].concat(
          MoneyHelper.display_with_percentage(dts, transactions, period_transactions)
        )
      end

      list.sort_by { |l| l[2] }.reverse
    end

    def total
      [padded_description(transactions.first.category, transactions)].concat(
        MoneyHelper.display_with_percentage(transactions, period_transactions, total_transactions)
      )
    end

    private

    def padded_description(value, transactions)
      whitespaces = SPACE_FOR_UNITS - 2 * ENCLOSING_UNIT - transactions.length.to_s.length
      "(#{transactions.count})#{' ' * whitespaces}#{value}"
    end
  end
end
