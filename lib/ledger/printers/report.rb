module Ledger
  module Printers
    # Class responsible for printing the table with the general report.
    class Report < Base
      def call(data)
        lines(data).each do |account, (*list, total)|
          title(account)

          table do
            main_header(from: :report)

            list.each { |line| add_row(line, CONFIG.color(:element)) }

            add_row(total, CONFIG.color(:total))
          end
        end

        total.call
      end

      private

      def lines(data)
        data.each_with_object({}) { |(account, list), res| res[account] = list.map { |info| line(info) } }
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
