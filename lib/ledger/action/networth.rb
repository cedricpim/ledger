module Ledger
  module Action
    # Class responsible for calculating the current networth and recalculate
    # previous entries.
    class Networth < Base
      def call
        new_entries = []
        repository.load(:networth) do |entry|
          new_entries << entry.exchange_to(currency).tap { |clone| clone.calculate_invested!(transactions) }
        end

        repository.add(new_entries + [Content.new(transactions, options).current_networth], type: :networth, reset: true)
      end

      private

      def transactions
        @transactions ||= repository.tap { |repo| repo.load(:ledger) }.entries[:ledger].map { |t| t.exchange_to(currency) }
      end

      def currency
        options[:currency]
      end
    end
  end
end
