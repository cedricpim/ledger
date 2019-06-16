module Ledger
  module Printers
    # Class responsible for printing a table with the totals values of the
    # ledger.
    class Total < Base
      TITLE = 'Totals'.freeze

      def call(period, total)
        period = with_period && prepare_period(period)
        total = CONFIG.show_totals? && prepare_total(total)

        title(TITLE)

        table { add_row(period, type: :header) } if period

        table { add_row(total, type: :header) } if total
      end

      private

      def prepare_period(data)
        line(data) do |values|
          values.flat_map do |element|
            element.map { |key, value| MoneyHelper.display_with_color(value, CONFIG.output(:totals, key)) }
          end
        end
      end

      def prepare_total(data)
        line(data) { |values| values.map { |value| [MoneyHelper.display(value), CONFIG.output(:totals, :total)] } }
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
