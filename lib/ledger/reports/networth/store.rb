module Ledger
  module Reports
    # Class responsible for generating the structure to save a Networth entry.
    class Networth::Store < Networth
      def data
        {date: date.to_s, invested: invested, investment: investment, amount: networth, currency: currency}
      end

      private

      def date
        @date ||= Date.today
      end

      def invested
        investments.select { |transaction| transaction.parsed_date == date }.sum(&:money).abs
      end
    end
  end
end
