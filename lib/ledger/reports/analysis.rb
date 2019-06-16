module Ledger
  module Reports
    # Class responsible for generating the table with the analysis of the
    # provided category.
    class Analysis < Base
      GLOBAL = 'Global'.freeze

      attr_reader :category

      def initialize(options, ledger: nil, category:)
        super(options, ledger: ledger)
        @category = category.upcase
      end

      def data
        @data ||= transactions.group_by(&:account).map { |account, ats| [account, list(ats)] }.to_h
      end

      def global
        @global ||= transactions.any? ? {GLOBAL => list(transactions)} : {}
      end

      private

      def list(transactions)
        result = transactions.group_by(&:description).map do |description, dts|
          statistics(transactions, period_transactions, title: description, transactions: dts)
        end

        result.sort_by { |elem| elem[:value] } + [total(transactions)]
      end

      def total(transactions)
        statistics(period_transactions, total_transactions, title: category, transactions: transactions)
      end

      def statistics(*other_transactions, title:, transactions:)
        {title: title, amount: transactions.length, value: transactions.sum(&:money)}.tap do |stats|
          stats[:percentages] = other_transactions.map { |ots| MoneyHelper.percentage(stats[:value], ots) }
        end
      end

      def filters
        [
          Filters::IncludeCategory.new(options, :report),
          Filters::IncludeAccount.new(options, :report)
        ]
      end

      def total_transactions
        @total_transactions ||= Filter.new(ledger, filters: filters, currency: currency).call
      end

      def period_transactions
        @period_transactions ||= Filter.new(total_transactions, filters: [Filters::Period.new(options)]).call
      end

      def transactions
        @transactions ||= Filter.new(period_transactions, filters: [Filters::Category.new(options, category)]).call
      end
    end
  end
end
