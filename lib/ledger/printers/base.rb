module Ledger
  # Module responsible for encapsulating all the classes that print any
  # information to STDOUT.
  module Printers
    # Class responsible for holding the common behaviour for printing
    # information to STDOUT.
    class Base
      include CommandLineReporter

      attr_reader :options, :total

      def initialize(options, total: nil)
        @options = options
        @total = total
      end

      private

      def main_header(from:)
        add_row(CONFIG.output(from, :header), CONFIG.output(from, :options), CONFIG.color(:header))
      end

      def title(title, options = {})
        header(CONFIG.output(:title).merge(title: title).merge(options))
      end

      def add_colored_row(cells, type: :element)
        return unless cells

        row(CONFIG.color(type)) { cells.each { |cell| column(*cell) } }
      end

      def add_row(cells, column_options = [], **row_options)
        return unless cells

        row(row_options) do
          cells.each_with_index { |cell, index| column(cell, column_options.fetch(index, {})) }
        end
      end
    end
  end
end
