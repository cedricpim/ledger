module Ledger
  # Class holding the transactions read from the ledger and used to query the
  # content of the ledger.
  class Content
    attr_reader :transactions, :options

    def initialize(transactions, options)
      @transactions = transactions.sort_by(&:parsed_date)
      @options = options
    end

    def list
      transactions.select { |t| options[:non_processed].nil? || t.processed == options[:non_processed] }
    end

    def accounts
      @accounts ||= transactions.group_by(&:account).each_with_object({}) do |(account, transactions), result|
        result[account] = transactions.map { |t| t.exchange_to(accounts_currency[account]) }.sum(&:money)
      end
    end

    def currencies
      @currencies ||= transactions.map(&:currency).uniq.each_with_object({}) do |currency, result|
        total = transactions.map { |t| t.exchange_to(currency) }.sum(&:money)

        result[total.currency] = MoneyHelper.display(total)
      end
    end

    def trips
      relevant_transactions.select(&:travel).group_by(&:travel).map do |t, trs|
        Trip.new(t, trs, transactions, options[:currency])
      end
    end

    def report
      if options[:global]
        [Report.new('Global', filtered_transactions, relevant_transactions, period, options[:currency])]
      else
        filtered_transactions.group_by(&:account).map { |a, trs| Report.new(a, trs, relevant_transactions, period) }
      end
    end

    def accounts_currency
      @accounts_currency ||= transactions.map(&:account).uniq.each_with_object({}) do |account, result|
        result[account] = transactions.find { |t| t.account == account }&.currency
      end
    end

    def relevant_transactions
      @relevant_transactions ||= transactions.reject do |transaction|
        CONFIG.default_excluded_categories.include?(transaction.category.downcase)
      end
    end

    private

    def filtered_transactions
      relevant_transactions.select { |t| filters.all? { |f| f.call(t) } }
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

    def filters
      [include_accounts, exclude_categories, from, till, month, year, travels].compact
    end

    def include_accounts
      return unless options[:accounts]

      ->(transaction) { options[:accounts].include?(transaction.account) }
    end

    def exclude_categories
      return unless options[:categories]

      ->(transaction) { !options[:categories].map(&:downcase).include?(transaction.category.downcase) }
    end

    def from
      return unless options[:from]

      ->(transaction) { transaction.parsed_date >= options[:from] }
    end

    def till
      return unless options[:till]

      ->(transaction) { transaction.parsed_date <= options[:till] }
    end

    def month
      return unless options[:month] && !filter_with_date_range?

      ->(transaction) { transaction.parsed_date.month == options[:month] }
    end

    def year
      return unless options[:year] && !filter_with_date_range?

      ->(transaction) { transaction.parsed_date.cwyear == options[:year] }
    end

    def travels
      return unless options[:travels]

      ->(transaction) { options[:travels].map(&:downcase).include?(transaction.travel&.downcase) }
    end

    def filter_with_date_range?
      options[:from] || options[:till]
    end
  end
end
