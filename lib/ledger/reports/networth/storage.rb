module Ledger
  module Reports
    # Class responsible for generating the structure to save a Networth entry.
    class Networth::Storage < Networth
      def data(entry)
        {
          date: entry&.parsed_date || Date.today,
          investment: entry&.valuation&.exchange_to(currency) || investment,
          amount: entry&.money&.exchange_to(currency) || networth,
          currency: currency
        }.tap { |attributes| attributes[:invested] = invested(attributes[:date]) }
      end

      private

      def invested(date)
        investments.select { |transaction| transaction.parsed_date == date }.sum(&:money).abs
      end
    end
  end
end
