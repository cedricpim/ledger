module Ledger
  module Printers
    # Class responsible for printing the table with the general report.
    class Report < Base
      private

      def type
        :report
      end

      def line(info)
        [
          padded_title(title: info[:title], amount: info[:amount]),
          MoneyHelper.display(info[:value]),
          info[:percentage]
        ]
      end
    end
  end
end
