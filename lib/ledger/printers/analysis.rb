module Ledger
  module Printers
    # Class responsible for printing the table with an analysis of a provided
    # category.
    class Analysis < Base
      private

      def type
        :analysis
      end

      def line(info)
        [
          padded_title(title: info[:title], amount: info[:amount]),
          MoneyHelper.display(info[:value]),
          *info[:percentages]
        ]
      end
    end
  end
end
