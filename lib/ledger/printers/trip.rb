module Ledger
  module Printers
    # Class responsible for printing the table with an analysis of a provided
    # trip.
    class Trip < Base
      attr_reader :global

      def initialize(total: nil, global:)
        super(total: total)
        @global = global
      end

      private

      def type
        global ? :globaltrip : :trip
      end

      def line(info)
        info.tap do
          info[:value] = MoneyHelper.display(info[:value])
          info[:percentage] = CONFIG.default_value if info[:percentage].nil?
        end.values
      end
    end
  end
end
