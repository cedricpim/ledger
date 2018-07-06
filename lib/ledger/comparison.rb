module Ledger
  # Module including all the method for creating the table, column and rows
  # used to display comparisons between categories.
  class Comparison
    # The array provided to give a some space between related columns
    WHITESPACE = [['', {}]].freeze

    # Array of arrays with the first element being the title of the header and
    # the second element the starting point for the periods
    HEADERS = [
      ['Category'],
      ['Totals', 0],
      ['Diffs', 1],
      ['Percentages', 1]
    ].freeze

    attr_reader :category, :transactions, :periods, :currency

    def initialize(category, transactions, periods, currency)
      @category = category
      @transactions = transactions
      @periods = periods
      @currency = currency
    end

    def list
      @list ||= title + WHITESPACE + totals + WHITESPACE + diffs + WHITESPACE + percentages
    end

    private

    def title
      [[category, {}]]
    end

    def totals
      compare(periods) { |period| value(period) }
    end

    def diffs
      compare(periods[1..-1], periods[0]) do |period, previous|
        value(period) + (value(previous) * -1)
      end
    end

    def percentages
      compare(periods[1..-1], periods[0]) do |period, previous|
        calculate_percentage(value(previous), value(period))
      end
    end

    def compare(periods, previous = nil)
      periods.map do |period|
        display = yield period, previous
        MoneyHelper.display_with_color(display).tap { previous = period }
      end
    end

    def calculate_percentage(prev_value, value)
      return if prev_value.zero? || value.zero?

      ((1 - value / prev_value).abs * (value > prev_value ? 1 : -1)).round(4) * 100
    end

    def value(period)
      money = transactions.select { |t| t.parsed_date.between?(*period) }.sum(&:money)
      money.zero? ? Money.new(money, currency) : money
    end
  end
end
