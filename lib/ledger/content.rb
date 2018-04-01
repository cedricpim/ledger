module Ledger
  # Class holding the transactions read from the ledger and used to query the
  # content of the ledger.
  class Content
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
        [GlobalTrips.new('Global', travel_transactions, current, options[:currency])]
      else
        travel_transactions.group_by(&:travel).map do |t, trs|
          Trip.new(t, trs, filtered_transactions, options[:currency])
        end.sort_by(&:date)
      end
    end

    def report
      if options[:global]
        [Report.new('Global', filtered_transactions, options[:currency])]
      else
        filtered_transactions.group_by(&:account).map { |acc, trs| Report.new(acc, trs, accounts_currency[acc]) }
      end
    end

    def study(category)
      if options[:global]
        [Study.new('Global', category_transactions(category), transactions, period_transactions, options[:currency])]
      else
        category_transactions(category).group_by(&:account).map do |a, trs|
          Study.new(a, trs, transactions, period_transactions, options[:currency])
        end
      end
    end

    def filtered_transactions
      @filtered_transactions ||= period_transactions.reject { |t| exclude_categories&.call(t) }
    end

    def excluded_transactions
      @excluded_transactions ||= period_transactions.select { |t| exclude_categories&.call(t) }
    end

    private

    def relevant_transactions
      @relevant_transactions ||= transactions.reject do |transaction|
        CONFIG.excluded_categories.any? { |c| c.match?(/#{transaction.category}/i) }
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
  end
end
