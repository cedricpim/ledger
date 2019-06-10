module Ledger
  module Action
    # Class responsible for converting the transactions to the main currency of
    # each account
    class Convert < Base
      def call
        entries = transactions.map { |transaction| transaction.exchange_to(currencies[transaction.account]) }

        repository.add(entries, reset: true)
      end

      private

      def transactions
        @transactions ||= repository.load(:ledger).to_a
      end

      def currencies
        @currencies ||= transactions.uniq(&:account).map do |transaction|
          [transaction.account, transaction.currency]
        end.to_h
      end
    end
  end
end
