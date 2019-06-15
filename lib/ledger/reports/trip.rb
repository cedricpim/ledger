module Ledger
  module Reports
    # Class responsible for generating the table with the analysis of the
    # provided trip.
    class Trip < Base
      GLOBAL = 'Global'.freeze

      TOTAL = 'Total'.freeze

      def data
        @data ||= build(options[:trip]&.upcase, group: :category, sort: :percentage, reverse: true)
      end

      def global
        @global ||= build(GLOBAL, group: :travel, sort: :title, reverse: false)
      end

      private

      def build(title, group:, sort:, reverse:)
        return {} unless transactions.any? && title

        {title => list(transactions, group: group, sort: sort, reverse: reverse)}
      end

      def list(transactions, group:, sort:, reverse:)
        result = transactions.group_by(&group).map do |title, gts|
          statistics(title: title, value: gts.sum(&:money), transactions: transactions)
        end

        result.sort_by { |elem| elem[sort] * (reverse ? -1 : 1) } + [total(transactions)]
      end

      def total(transactions)
        statistics(title: TOTAL, value: transactions.sum(&:money), transactions: [])
      end

      def statistics(title:, value:, transactions:)
        {title: title, value: value, percentage: MoneyHelper.percentage(value, transactions)}
      end

      def filters
        [
          Filters::IncludeCategory.new(options, :report)
        ]
      end

      def total_transactions
        @total_transactions ||= Filter.new(ledger, filters: filters, currency: currency).call
      end

      def transactions
        @transactions ||= Filter.new(total_transactions, filters: filters + [Filters::Trip.new(options)]).call
      end
    end
  end
end
