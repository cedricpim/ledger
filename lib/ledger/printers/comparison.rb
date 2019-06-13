module Ledger
  module Printers
    # Class responsible for printing the table with the comparisons of
    # different months.
    class Comparison < Base
      # The array provided to give a some space between related columns
      WHITESPACE = ['', width: 2].freeze

      # Table title
      TITLE = 'Comparison'

      # Array of arrays with the first element being the title of the header and
      # the second element the starting point for the periods
      HEADERS = [
        ['Category'],
        ['Total', 0],
        ['+/-', 1],
        ['%', 1]
      ].freeze

      def call
        title(TITLE, width: table_width)

        table do
          add_colored_row(headers, type: :header)

          lines.each { |line| add_colored_row(line) }

          add_colored_row(totals)
        end
      end

      private

      def report
        @report ||= Reports::Comparison.new(options, ledger: ledger)
      end

      def lines
        @lines ||= report.data.map { |info| line(info) }
      end

      def totals
        @totals ||= line(report.totals, totals: true)
      end

      def headers
        @headers ||= widths.slice_after(&:zero?).map.with_index do |group, header_index|
          build_header_columns(group, header_index)
        end.flatten(1)
      end

      def line(info, totals: false)
        info.each_pair.with_object([]) do |(key, value), result|
          result << WHITESPACE unless result.empty?

          if key == :title
            result << [value, totals ? {color: :yellow} : {}]
          else
            value.each { |elem| result << MoneyHelper.display_with_color(elem) }
          end
        end
      end

      def table_width
        headers.sum { |_elem, width:, **options| width + 1 }
      end

      def widths
        Array.new(totals.count) { |index| (lines + [totals]).map { |line| line[index][0].length }.max }
      end

      def build_header_columns(group, header_index)
        group.map.with_index do |width, period_index|
          next WHITESPACE if width.zero?

          title = build_column_title(header_index, period_index)
          [title, width: [width, title.length].max + 1, align: 'center']
        end
      end

      def build_column_title(header_index, period_index)
        dates = report.periods.flatten.map { |p| p.strftime('%m/%y') }.uniq

        title, starting = HEADERS[header_index]

        starting ? "#{title} (#{dates[period_index + starting]})" : title
      end
    end
  end
end
