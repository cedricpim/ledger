module Ledger
  module Printers
    # Class responsible for printing the table with the balance of each
    # account.
    class Balance < Base
      TITLE = 'Balance'

      def call
        title(TITLE)

        table do
          main_header(from: :balance)

          lines.each { |line| add_colored_row(line) }
        end

        total.call
      end

      private

      def report
        @report ||= Reports::Balance.new(options)
      end

      def lines
        @lines ||= report.data.map { |info| line(info) }.reject(&:empty?)
      end

      def line(info)
        return [] unless info[:value]

        info.each_pair.with_object([]) do |(key, value), result|
          if key == :title
            result << [value, CONFIG.output(:balance, :options)[0]]
          else
            result << MoneyHelper.display_with_color(value, CONFIG.output(:balance, :options)[1])
          end
        end
      end

      def totals_with_period
        false
      end
    end
  end
end
