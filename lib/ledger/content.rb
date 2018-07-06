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
      @currencies ||= transactions.map(&:currency).uniq
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
        [GlobalTrips.new('Global', travel_transactions, relevant_transactions)]
      else
        travel_transactions.group_by(&:travel).map do |t, tts|
          Trip.new(t, tts, filtered_transactions)
        end.sort_by(&:date)
      end
    end

    def comparisons
      transactions_for_comparison.group_by(&:category).map do |c, cts|
        Comparison.new(c, cts, periods, options[:currency])
      end
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
      @relevant_transactions ||= begin
        list = transactions.reject do |transaction|
          CONFIG.excluded_categories.any? { |c| c.match?(/#{transaction.category}/i) }
        end
        options[:currency] && options[:global] ? list.map { |elem| elem.exchange_to(options[:currency]) } : list
      end
    end

    def period_transactions
      @period_transactions ||= relevant_transactions.select { |t| t.parsed_date.between?(*period) }
    end

    def travel_transactions
      filtered_transactions.select { |t| t.travel && (options[:trip].nil? || t.travel.match?(/#{options[:trip]}/i)) }
    end

    def category_transactions(category)
      filtered_transactions.select { |t| t.category.match?(/#{category}/i) }
    end

    def transactions_for_comparison
      initial = periods.first.first

      transactions.map do |t|
        next unless t.parsed_date > initial

        t.exchange_to(options[:currency])
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
  end
end
