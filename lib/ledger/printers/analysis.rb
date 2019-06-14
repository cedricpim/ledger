module Ledger
  module Printers
    # Class responsible for printing the table with an analysis of a provided
    # category.
    class Analysis < Base
      # Space reserved for displaying the amount of entries
      SPACE_FOR_UNITS = 6
      # Space used by characters that enclose each side of the amount
      ENCLOSING_UNIT = 1
      # Space used to separate title and amount
      WHITESPACE = ' '.freeze

      attr_reader :category

      def initialize(options, ledger: nil, category:)
        super(options, ledger: ledger)
        @category = category
      end

      def call
        lines.each do |account, (*list, total)|
          title(account)

          table do
            main_header(from: :analysis)

            list.each { |line| add_row(line, CONFIG.color(:element)) }

            add_row(total, CONFIG.color(:total))
          end
        end

        total.call
      end

      private

      def report
        @report ||= Reports::Analysis.new(options, ledger: ledger, category: category)
      end

      def lines
        @lines ||= (options[:global] ? report.global : report.data).each.with_object({}) do |(account, list), result|
          result[account] = list.map { |info| line(info) }
        end
      end

      def line(info)
        [
          padded_title(title: info[:title], amount: info[:amount]),
          MoneyHelper.display(info[:value]),
          *info[:percentages]
        ]
      end

      def padded_title(title:, amount:)
        whitespaces = SPACE_FOR_UNITS - (2 * ENCLOSING_UNIT) - amount.to_s.length
        ["(#{amount})", WHITESPACE * whitespaces, title].join
      end

      def total
        @total ||= Total.new(options.merge(with_period: true), ledger: report.ledger)
      end
    end
  end
end
