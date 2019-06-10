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

      def title(title, options = {})
        header(CONFIG.output(:title).merge(title: title).merge(options))
      end

      def add_colored_row(lines, type: :element)
        return unless lines

        row(CONFIG.color(type)) { lines.each { |line| column(*line) } }
      end
    end
  end
end
