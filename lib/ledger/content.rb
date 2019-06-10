module Ledger
  # Class holding the transactions read from the ledger and used to query the
  # content of the ledger.
  class Content # rubocop:disable Metrics/ClassLength
    attr_reader :transactions, :options

    def initialize(transactions, options)
      @transactions = transactions.sort_by(&:parsed_date)
      @options = options
    end

    attr_reader :account_inclusion

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
        total = ts.sum { |transaction| exchange_on_date(transaction, acc) }
        result[acc] = total if options[:all] || !total.zero?
      end
    end

    def current
      @current ||= accounts.values.sum { |m| m.exchange_to(currencies.first) }
    end

    def trips
      including do
        if options[:global] && !options[:trip]
          [GlobalTrip.new('Global', travel_transactions, relevant_transactions)]
        else
          travel_transactions.group_by(&:travel).map do |t, tts|
            Trip.new(t, tts, filtered_transactions)
          end.sort_by(&:date)
        end
      end
    end

    def reports
      if options[:global]
        [Report.new('Global', filtered_transactions)]
      else
        filtered_transactions.group_by(&:account).map { |acc, trs| Report.new(acc, trs) }
      end
    end

    def analyses(category)
      if options[:global]
        [Analysis.new('Global', category_transactions(category), period_transactions, relevant_transactions)]
      else
        category_transactions(category).group_by(&:account).map do |a, trs|
          Analysis.new(a, trs, period_transactions, relevant_transactions)
        end
      end
    end

    def filtered_transactions
      # Filter.new(exchanged_list, filters: [
      #   Filters::ExcludeCategory.new(options, :report),
      #   Filters::ExcludeAccount.new(options, :report),
      #   Filters::Period.new(options)
      # ])
      @filtered_transactions ||= period_transactions.reject { |t| exclude_categories&.call(t) }
    end

    def excluded_transactions
      # Filter.new(exchanged_list, filters: [
      #   Filters::ExcludeCategory.new(options, :report),
      #   Filters::ExcludeAccount.new(options, :report),
      #   Filters::Period.new(options)
      # ])
      @excluded_transactions ||= period_transactions.select { |t| exclude_categories&.call(t) }
    end

    private

    def including
      @account_inclusion = true
      result = yield
      @account_inclusion = false
      result
    end

    def relevant_transactions
      exchanged_list.reject do |t|
        exclusions[:categories].include?(t.category.downcase) || (!account_inclusion && exclusions[:accounts].include?(t.account.downcase))
      end
    end

    def exclusions
      @exclusions ||= CONFIG.exclusions(of: :report).transform_values { |values| values.map(&:downcase) }
    end

    def period_transactions
      # Filter.new(exchanged_list, filters: [
      #   Filters::ExcludeCategory.new(options, :report),
      #   Filters::ExcludeAccount.new(options, :report),
      #   Filters::Period.new(options)
      # ])
      @period_transactions ||= relevant_transactions.select { |t| t.parsed_date.between?(*period) }
    end

    def travel_transactions
      # Filter.new(exchanged_list, filters: [
      #   Filters::ExcludeCategory.new(options, :report),
      #   Filters::ExcludeAccount.new(options, :report),
      #   Filters::Period.new(options),
      #   Filters::Travel.new(options)
      # ])
      period_transactions.select { |t| t.travel && (options[:trip].nil? || t.travel.match?(/#{options[:trip]}/i)) }
    end

    def category_transactions(category)
      # Filter.new(exchanged_list, filters: [
      #   Filters::ExcludeCategory.new(options, :report),
      #   Filters::ExcludeAccount.new(options, :report),
      #   Filters::Period.new(options),
      #   Filters::Category.new(options, category),
      # ])
      period_transactions.select { |t| t.category.casecmp(category).zero? }
    end

    def exchange_on_date(transaction, acc)
      return Money.new(0, accounts_currency[acc]) if options[:date] && transaction.parsed_date > options[:date]

      transaction.exchange_to(accounts_currency[acc]).money
    end

    def exclude_categories
      return unless options[:categories]

      ->(transaction) { options[:categories].map(&:downcase).include?(transaction.category.downcase) }
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

    def exchanged_list
      @exchanged_list = transactions.map { |elem| currency ? elem.exchange_to(currency) : elem }
    end

    def currency
      options[:currency]
    end
  end
end
