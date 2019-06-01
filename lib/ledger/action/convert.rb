module Ledger
  # Module responsible for encapsulating the actions that can be done to the
  # Ledger
  module Action
    # Class responsible for converting the transactions to the main currency of
    # each account
    class Convert
      def call
        transactions = repository.transactions.map do |transaction|
          transaction.exchange_to(repository.accounts_currency[transaction.account])
        end
        repository.add(transactions, reset: true)
      end

      private

      def repository
        @repository ||= Repository.new
      end
    end
  end
end
