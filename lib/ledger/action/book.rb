module Ledger
  module Action
    # Class responsible for adding a transaction to the ledger
    class Book < Base
      def call
        transaction = TransactionBuilder.new(values: options[:transaction]).build!

        repository.add(transaction)
      end
    end
  end
end
