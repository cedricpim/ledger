module Ledger
  # Class holding the transactions read from the ledger and used to query the
  # content of the ledger.
  class Content # rubocop:disable Metrics/ClassLength
    attr_reader :transactions, :options

    def initialize(transactions, options)
      @transactions = transactions.sort_by(&:parsed_date)
      @options = options
    end

    def currencies
      @currencies ||= transactions.group_by(&:currency).reject { |_cur, ts| ts.sum(&:money).zero? }.keys
    end

    def accounts_currency
      @accounts_currency ||= transactions.uniq(&:account).each_with_object({}) do |t, result|
        result[t.account] = t.currency
      end
    end

    def accounts
      @accounts ||= transactions.group_by(&:account).each_with_object({}) do |(acc, ts), result|
        result[acc] = ts.sum { |t| t.exchange_to(accounts_currency[acc]).money }
      end
    end

    def current
      @current ||= accounts.values.sum { |m| m.exchange_to(currencies.first) }
    end

    def trips
      if options[:global]
        [GlobalTrip.new('Global', travel_transactions, relevant_transactions)]
      else
        travel_transactions.group_by(&:travel).map do |t, tts|
          Trip.new(t, tts, filtered_transactions)
        end.sort_by(&:date)
      end
    end

    def comparisons
      totals_comparison = Comparison.new('Totals', transactions_for_comparison, periods, currency)

      transactions_for_comparison.group_by(&:category).map do |c, cts|
        Comparison.new(c, cts, periods, currency)
      end.sort_by(&:category) + [totals_comparison]
    end

    def reports
      if options[:global]
        [Report.new('Global', filtered_transactions)]
      else
        filtered_transactions.group_by(&:account).map { |acc, trs| Report.new(acc, trs) }
      end
    end

    def studies(category)
      if options[:global]
        [Study.new('Global', category_transactions(category), period_transactions, relevant_transactions)]
      else
        category_transactions(category).group_by(&:account).map do |a, trs|
          Study.new(a, trs, period_transactions, relevant_transactions)
        end
      end
    end

    def filtered_transactions
      @filtered_transactions ||= period_transactions.reject { |t| exclude_categories&.call(t) }
    end

    def excluded_transactions
      @excluded_transactions ||= period_transactions.select { |t| exclude_categories&.call(t) }
    end

    def periods
      @periods ||= (current_period + previous_periods).sort
    end

    private

    def relevant_transactions
      @relevant_transactions ||= transactions.map do |t|
        next if CONFIG.excluded_categories.any? { |c| c.casecmp(t.category).zero? }

        options[:global] && currency ? t.exchange_to(currency) : t
      end.compact
    end

    def period_transactions
      @period_transactions ||= relevant_transactions.select { |t| t.parsed_date.between?(*period) }
    end

    def travel_transactions
      period_transactions.select { |t| t.travel && (options[:trip].nil? || t.travel.match?(/#{options[:trip]}/i)) }
    end

    def category_transactions(category)
      period_transactions.select { |t| t.category.casecmp(category).zero? }
    end

    def transactions_for_comparison
      @transactions_for_comparison ||= relevant_transactions.map do |t|
        next unless t.parsed_date > periods.first.first

        t.exchange_to(currency)
      end.compact
    end

    def period
      if filter_with_date_range?
        [options.fetch(:from, -Float::INFINITY), options.fetch(:till, Float::INFINITY)]
      elsif options[:month] && options[:year]
        [build_date(1), build_date(-1)]
      else
        [-Float::INFINITY, Float::INFINITY]
      end
    end

    def build_date(day)
      Date.new(options[:year], options[:month], day)
    end

    def filter_with_date_range?
      options[:from] || options[:till]
    end

    def exclude_categories
      return unless options[:categories]

      ->(transaction) { options[:categories].map(&:downcase).include?(transaction.category.downcase) }
    end

    def current_period
      [range(Date.today.year, Date.today.month)]
    end

    def previous_periods
      current_year = Date.today.year
      current_month = Date.today.month

      Array.new(options[:months]) do
        current_year, current_month =
          current_month > 1 ? [current_year, current_month - 1] : [current_year - 1, 12]

        range(current_year, current_month)
      end
    end

    def range(year, month)
      [Date.new(year, month, 1), Date.new(year, month, -1)]
    end

    def currency
      options[:currency]
    end
  end
end
