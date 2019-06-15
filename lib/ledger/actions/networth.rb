module Ledger
  module Actions
    # Class responsible for calculating the current networth and recalculate
    # previous entries.
    class Networth < Base
      def call(data)
        entries = repository.load(:networth).map do |entry|
          entry.exchange_to(currency).tap { |clone| clone.calculate_invested!(transactions) }
        end

        entries << Ledger::Networth.new(data)

        repository.add(entries, resource: :networth, reset: true)
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
