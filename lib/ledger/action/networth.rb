module Ledger
  module Action
    # Class responsible for calculating the current networth and recalculate
    # previous entries.
    class Networth < Base
      def call
        entries = repository.load(:networth).map do |entry|
          entry.exchange_to(currency).tap { |clone| clone.calculate_invested!(transactions) }
        end

        entries << NetworthCalculation.new(transactions, currency).networth

        repository.add(entries, type: :networth, reset: true)
      end

      private

      def transactions
        @transactions ||= repository.load(:ledger)
      end

      def currency
        options[:currency]
      end
    end
  end
end
