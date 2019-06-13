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
        @report ||= Reports::Balance.new(options, ledger: ledger)
      end

      def lines
        @lines ||= report.data.map { |info| line(info) }.compact
      end

      def line(info)
        return unless info[:value]

        info.each_pair.with_index.map do |(key, value), index|
          options = CONFIG.output(:balance, :options)[index]

          key == :title ? [value, options] : MoneyHelper.display_with_color(value, options)
        end
      end

      def total
        @total ||= Total.new(options.merge(with_period: false), ledger: report.ledger)
      end
    end
  end
end
