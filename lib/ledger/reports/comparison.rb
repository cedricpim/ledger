module Ledger
  module Reports
    # Class responsible for generating the table with the comparisons of
    # different months.
    class Comparison < Base
      TOTALS = 'Totals'.freeze

      def periods
        @periods ||= (current_period + previous_periods).sort
      end

      def data
        @data ||= transactions.keys.map { |category| statistics(category) }
      end

      def totals
        @totals ||= statistics(TOTALS)
      end

      private

      def filters
        [
          Filters::IncludeCategory.new(options, :report),
          Filters::Period.new(options.merge(from: periods.first.first))
        ]
      end

      def transactions
        @transactions ||= super.group_by(&:category).sort.to_h
      end

      def statistics(category)
        {
          title: category,
          absolutes: absolutes(category),
          diffs: diffs(category),
          percentages: percentages(category)
        }
      end

      def absolutes(category)
        compare(category, absolute: true) { |_prev_value, value| value }
      end

      def diffs(category)
        compare(category) { |prev_value, value| value + (prev_value * -1) }
      end

      def percentages(category)
        compare(category) do |prev_value, value|
          next if prev_value.zero? || value.zero?

          ((1 - value / prev_value).abs * (value > prev_value ? 1 : -1) * 100).to_f.round(2)
        end
      end

      def compare(category, absolute: false)
        previous, rest = absolute ? [nil, periods] : [periods[0], periods[1..-1]]

        cts = transactions[category] || transactions.values.flatten

        rest.map do |period|
          yield(value(previous, cts), value(period, cts)).tap { previous = period }
        end
      end

      def value(period, transactions)
        return unless period

        money = transactions.sum { |transaction| transaction.parsed_date.between?(*period) ? transaction.money : 0 }
        money.zero? ? Money.new(money, currency) : money
      end

      def current_period
        [range(Date.today.year, Date.today.month)]
      end

      def previous_periods
        current_year = Date.today.year
        current_month = Date.today.month

        Array.new(options[:months]) do
          current_year, current_month = current_month > 1 ? [current_year, current_month - 1] : [current_year - 1, 12]

          range(current_year, current_month)
        end
      end

      def range(year, month)
        [Date.new(year, month, 1), Date.new(year, month, -1)]
      end
    end
  end
end
