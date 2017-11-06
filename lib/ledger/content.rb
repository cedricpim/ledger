module Ledger
  # Class holding the transactions read from the ledger and used to query the
  # content of the ledger.
  class Content
    attr_reader :transactions

    def initialize(transactions)
      @transactions = transactions
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
      transactions.select(&:travel).group_by(&:travel).map do |t, trs|
        Trip.new(t, trs, transactions, options[:currency])
      end
    end

    def report(options)
      if options[:global]
        [Report.new('Global', filtered_transactions(options), transactions, options[:monthly], options[:currency])]
      else
        filtered_transactions(options).group_by(&:account).map do |a, trs|
          Report.new(a, trs, transactions, options[:monthly])
        end
      end
    end

    def accounts_currency
      @accounts_currency ||= transactions.map(&:account).uniq.each_with_object({}) do |account, result|
        result[account] = transactions.find { |t| t.account == account }&.currency
      end
    end

    private

    def filtered_transactions(options)
      transactions.select { |t| filters(options).all? { |f| f.call(t) } }
    end

    def filters(options)
      [
        include_accounts(options),
        from(options),
        till(options),
        exclude(options),
        monthly(options),
        annual(options),
        travels(options)
      ].compact
    end

    def include_accounts(options)
      return unless options[:accounts]

      ->(transaction) { options[:accounts].include?(transaction.account) }
    end

    def from(options)
      return unless options[:from]

      ->(transaction) { transaction.parsed_date >= options[:from] }
    end

    def till(options)
      return unless options[:till]

      ->(transaction) { transaction.parsed_date <= options[:till] }
    end

    def exclude(options)
      return unless options[:categories]

      ->(transaction) { !options[:categories].map(&:downcase).include?(transaction.category.downcase) }
    end

    def monthly(options)
      return unless options[:monthly]

      ->(transaction) { transaction.parsed_date.month == options[:monthly] }
    end

    def annual(options)
      return unless options[:annual]

      ->(transaction) { transaction.parsed_date.cwyear == options[:annual] }
    end

    def travels(options)
      return unless options[:travels]

      ->(transaction) { options[:travels].map(&:downcase).include?(transaction.travel&.downcase) }
    end
  end
end
