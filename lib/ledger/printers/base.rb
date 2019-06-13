module Ledger
  # Module responsible for encapsulating all the classes that print any
  # information to STDOUT.
  module Printers
    # Class responsible for holding the common behaviour for printing
    # information to STDOUT.
    class Base
      include CommandLineReporter

      attr_reader :options

      def initialize(options)
        @options = options
      end

      private

      def main_header(from:)
        add_row(CONFIG.output(from, :header), CONFIG.output(from, :options), CONFIG.color(:header))
      end

      def title(title, options = {})
        header(CONFIG.output(:title).merge(title: title).merge(options))
      end

      def add_colored_row(lines, type: :element)
        return unless lines

        row(CONFIG.color(type)) { lines.each { |line| column(*line) } }
      end

      def add_row(lines, column_options = [], **row_options)
        return unless lines

        row(row_options) do
          lines.each_with_index { |value, index| column(value, column_options.fetch(index, {})) }
        end
      end

      def total
        @total ||= Total.new(options.merge(with_period: totals_with_period))
      end

      def totals_with_period
        false
      end
    end
  end
end
