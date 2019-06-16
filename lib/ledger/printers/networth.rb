module Ledger
  module Printers
    # Class responsible for printing the table with the value of each
    # investment plus the current cash.
    class Networth < Base
      TITLE = 'Networth Balance'.freeze

      def call(data)
        title(TITLE)

        table(width: :auto) do
          main_header(from: :networth)

          *list, total = data.map { |info| line(info) }

          list.each { |line| add_row(line) }

          add_row(total, type: :total)
        end
      end

      private

      def line(info)
        info.tap { info[:value] = MoneyHelper.display(info[:value]) }.values
      end
    end
  end
end
