module Ledger
  # Class holding the transactions read from the ledger and used to query the
  # content of the ledger.
  class Content
    attr_reader :transactions

    def initialize(transactions)
      @transactions = transactions.sort_by(&:parsed_date)
    end

    def list(options)
      transactions.select { |t| options[:non_processed].nil? || t.processed == options[:non_processed] }
    end

    def currencies
      @currencies ||= transactions.map(&:currency).uniq.each_with_object({}) do |currency, result|
        total = transactions.map { |t| t.exchange_to(currency) }.sum(&:money)

        result[total.currency] = MoneyHelper.display(total)
      end
    end

    def trips(options)
      relevant_transactions.select(&:travel).group_by(&:travel).map do |t, trs|
        Trip.new(t, trs, transactions, options[:currency])
      end
    end

    def report(options)
      params = [relevant_transactions, period(options)]

      if options[:global]
        [Report.new('Global', filtered_transactions(options), *params, options[:currency])]
      else
        filtered_transactions(options).group_by(&:account).map { |a, trs| Report.new(a, trs, *params) }
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

    def filtered_transactions(options)
      relevant_transactions.select { |t| filters(options).all? { |f| f.call(t) } }
    end

    def period(options)
      if filter_with_date_range?(options)
        [options.fetch(:from, -Float::INFINITY), options.fetch(:till, Float::INFINITY)]
      else
        [Date.new(options[:year], options[:month], 1), Date.new(options[:year], options[:month], -1)]
      end
    end

    def filters(options)
      [
        include_accounts(options),
        exclude_categories(options),
        from(options),
        till(options),
        month(options),
        year(options),
        travels(options)
      ].compact
    end

    def include_accounts(options)
      return unless options[:accounts]

      ->(transaction) { options[:accounts].include?(transaction.account) }
    end

    def exclude_categories(options)
      return unless options[:categories]

      ->(transaction) { !options[:categories].map(&:downcase).include?(transaction.category.downcase) }
    end

    def from(options)
      return unless options[:from]

      ->(transaction) { transaction.parsed_date >= options[:from] }
    end

    def till(options)
      return unless options[:till]

      ->(transaction) { transaction.parsed_date <= options[:till] }
    end

    def month(options)
      return unless options[:month] && !filter_with_date_range?(options)

      ->(transaction) { transaction.parsed_date.month == options[:month] }
    end

    def year(options)
      return unless options[:year] && !filter_with_date_range?(options)

      ->(transaction) { transaction.parsed_date.cwyear == options[:year] }
    end

    def travels(options)
      return unless options[:travels]

      ->(transaction) { options[:travels].map(&:downcase).include?(transaction.travel&.downcase) }
    end

    def filter_with_date_range?(options)
      options[:from] || options[:till]
    end
  end
end
