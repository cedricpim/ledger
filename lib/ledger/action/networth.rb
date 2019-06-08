module Ledger
  module Action
    # Class responsible for calculating the current networth and recalculate
    # previous entries.
    class Networth < Base
      def call
        entries = repository.load(:networth).map do |entry|
          entry.exchange_to(currency).tap { |clone| clone.calculate_invested!(transactions) }
        end

        repository.add(entries + [Content.new(transactions, options).current_networth], type: :networth, reset: true)
      end

      private

      def transactions
        @transactions ||= repository.load(:ledger).to_a
      end

      def currency
        options[:currency]
      end
    end
  end
end
