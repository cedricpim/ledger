module Ledger
  # Class holding the transactions read from the ledger and used to query the
  # content of the ledger.
  class Content
    attr_reader :transactions, :options

    def initialize(transactions, options)
      @transactions = transactions.sort_by(&:parsed_date).reject do |transaction|
        CONFIG.excluded_categories.any? { |c| c.match?(/#{transaction.category}/i) }
      end
      @options = options
    end

    def accounts
      @accounts ||= transactions.group_by(&:account).each_with_object({}) do |(account, transactions), result|
        result[account] = transactions.map { |t| t.exchange_to(accounts_currency[account]) }.sum(&:money)
      end
    end

    def currencies
      @currencies ||= transactions.map(&:currency).uniq
    end

    def current
      @current ||= transactions.sum { |t| t.exchange_to(currencies.first).money }
    end

    def trips
      transactions.select(&:travel).group_by(&:travel).map do |t, trs|
        Trip.new(t, trs, transactions, options[:currency])
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
      category_transactions = filtered_transactions.select { |t| t.category.casecmp?(category) }

      if options[:global]
        [Study.new('Global', category_transactions, transactions, period, options[:currency])]
      else
        category_transactions.group_by(&:account).map { |a, trs| Study.new(a, trs, transactions, period) }
      end
    end

    def accounts_currency
      @accounts_currency ||= transactions.map(&:account).uniq.each_with_object({}) do |account, result|
        result[account] = transactions.find { |t| t.account == account }&.currency
      end
    end

    def filtered_transactions
      @filtered_transactions ||= period_transactions.select { |t| !exclude_categories&.call(t) }
    end

    def excluded_transactions
      @excluded_transactions ||= period_transactions.select { |t| exclude_categories&.call(t) }
    end

    private

    def period_transactions
      @period_transactions ||= transactions.select { |t| t.parsed_date.between?(*period) }
    end

    def period
      if filter_with_date_range?
        [options.fetch(:from, -Float::INFINITY), options.fetch(:till, Float::INFINITY)]
      else
        [build_date(1), build_date(-1)]
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
