module Ledger
  # Module responsible for encapsulating all the classes that print any
  # information to STDOUT.
  module Printers
    # Class responsible for holding the common behaviour for printing
    # information to STDOUT.
    class Base
      include CommandLineReporter

      # Space reserved for displaying the amount of entries
      SPACE_FOR_UNITS = 6
      # Space used by characters that enclose each side of the amount
      ENCLOSING_UNIT = 1
      # Space used to separate title and amount
      WHITESPACE = ' '.freeze

      attr_reader :options, :total

      def initialize(options, total: nil)
        @options = options
        @total = total
      end

      def call(data)
        lines(data).each do |account, (*list, total)|
          title(account)

          table do
            main_header(from: type)

            list.each { |line| add_row(line) }

            add_row(total, type: :total)
          end
        end

        total&.call
      end

      private

      def lines(data)
        data.each_with_object({}) { |(account, list), res| res[account] = list.map { |info| line(info) } }
      end

      def main_header(from:)
        add_row(CONFIG.output(from, :header).zip(CONFIG.output(from, :options)), type: :header)
      end

      def title(title, options = {})
        header(CONFIG.output(:title).merge(title: title).merge(options))
      end

      def add_row(cells, type: :element)
        return unless cells

        row(CONFIG.color(type)) { cells.each { |cell| column(*Array(cell)) } }
      end

      def padded_title(title:, amount:)
        whitespaces = SPACE_FOR_UNITS - (2 * ENCLOSING_UNIT) - amount.to_s.length
        ["(#{amount})", WHITESPACE * whitespaces, title].join
      end
    end
  end
end
