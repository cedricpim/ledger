module Ledger
  module Printers
    # Class responsible for printing a table with the totals values of the
    # ledger.
    class Total < Base
      extend Memoist

      TITLE = 'Totals'.freeze

      def call
        title(TITLE)

        table { add_colored_row(period, type: :header) } if with_period && period

        table { add_colored_row(total, type: :header) } if total && CONFIG.show_totals?
      end

      private

      def report
        @report ||= Reports::Total.new(options)
      end

      memoize def total
        line(report.total) do |values|
          values.map.with_index do |value, index|
            [MoneyHelper.display(value), CONFIG.output(:totals, :total)]
          end
        end
      end

      memoize def period
        line(report.period) do |values|
          values.flat_map do |element|
            element.map { |key, value| MoneyHelper.display_with_color(value, CONFIG.output(:totals, key)) }
          end
        end
      end

      def line(values:, percentage:, &block)
        return if values.empty?

        (block.call(values) + [Array(percentage(value: percentage))]).reject(&:empty?)
      end

      def percentage(value:)
        return unless with_period

        # TODO: move after refactoring
        options = CONFIG.output(:totals, :percentage).select { |key, _value| %i[width align].include?(key) }
        MoneyHelper.display_with_color(value, options)
      end

      def with_period
        options[:with_period]
      end
    end
  end
end
