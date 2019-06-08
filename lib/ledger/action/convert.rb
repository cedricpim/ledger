module Ledger
  module Action
    # Class responsible for converting the transactions to the main currency of
    # each account
    class Convert < Base
      def call
        transactions = repository.load(:ledger).map do |transaction|
          transaction.exchange_to(repository.accounts_currency[transaction.account])
        end

        repository.add(transactions, reset: true)
      end
    end
  end
end
