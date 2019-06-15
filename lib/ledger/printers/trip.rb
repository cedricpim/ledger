module Ledger
  module Printers
    # Class responsible for printing the table with an analysis of a provided
    # trip.
    class Trip < Base
      def call(data)
        lines(data).each do |account, (*list, total)|
          title(account)

          table do
            main_header(from: options[:global] ? :globaltrip : :trip)

            list.each { |line| add_row(line, CONFIG.color(:element)) }

            add_row(total, CONFIG.color(:total))
          end
        end
      end

      private

      def lines(data)
        data.each_with_object({}) { |(account, list), res| res[account] = list.map { |info| line(info) } }
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
