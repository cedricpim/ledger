module Ledger
  # Class responsible for doing the correct calculations to generate reports
  # about the income/expenses of the account.
  class Report
    # Space reserved for displaying the amount of entries
    SPACE_FOR_UNITS = 6
    # Space used by characters that enclose each side of the amount
    ENCLOSING_UNIT = 1

    attr_reader :account, :filtered_transactions

    def initialize(account, filtered_transactions, currency)
      @account = account
      @filtered_transactions = filtered_transactions.map { |t| t.exchange_to(currency) }
    end

    def categories
      list = filtered_transactions.group_by(&:category).map do |category, cts|
        total = cts.sum(&:money)
        [
          padded_category(category, cts),
          MoneyHelper.display(total),
          MoneyHelper.percentage(total, filtered_transactions)
        ]
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
