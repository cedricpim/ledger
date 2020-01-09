module Ledger
  module Actions
    # Class responsible for calculating the current networth and recalculate
    # previous entries.
    class Networth < Base
      def call(data)
        entries = repository.load(:networth).map { |entry| Ledger::Networth.new(report.store(entry: entry)) }

        entries << Ledger::Networth.new(data)

        repository.add(entries, resource: :networth, reset: true)
      end

      private

      def report
        @report ||= Ledger::Reports::Networth.new(options.merge(ledger: ledger))
      end
    end
  end
end
