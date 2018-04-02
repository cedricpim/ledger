module Ledger
  # Class responsible for doing the correct calculations to generate reports
  # about the income/expenses of the account.
  class Report
    # Space reserved for displaying the amount of entries
    SPACE_FOR_UNITS = 6
    # Space used by characters that enclose each side of the amount
    ENCLOSING_UNIT = 1

    attr_reader :account, :transactions

    def initialize(account, transactions)
      @account = account
      @transactions = transactions
    end

    def list
      list = transactions.group_by(&:category).map do |category, cts|
        [padded_category(category, cts)].concat(MoneyHelper.display_with_percentage(cts, transactions))
      end

      list.sort_by { |l| l[2] }.reverse
    end

    private

    def padded_category(category, transactions)
      whitespaces = SPACE_FOR_UNITS - 2 * ENCLOSING_UNIT - transactions.length.to_s.length
      "(#{transactions.count})#{' ' * whitespaces}#{category}"
    end
  end
end
