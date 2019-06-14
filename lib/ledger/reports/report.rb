module Ledger
  module Reports
    # Class responsible for generating the table with the general report.
    class Report < Base
      GLOBAL = 'Global'.freeze

      def data
        @data ||= transactions.group_by(&:account).map { |account, ats| [account, list(ats)] }.to_h
      end

      def global
        @global ||= transactions.any? ? {GLOBAL => list(transactions)} : {}
      end

      private

      def filters
        [
          Filters::IncludeCategory.new(options, :report),
          Filters::IncludeAccount.new(options, :report),
          Filters::Period.new(options),
          Filters::PresentCategory.new(options)
        ]
      end

      def list(transactions)
        result = transactions.group_by(&:category).map { |category, cts| statistics(title: category, cts: cts) }

        result.sort_by { |elem| elem[:value] }
      end

      def statistics(title:, cts:)
        value = cts.sum(&:money)

        {title: title, amount: cts.length, value: value, percentage: MoneyHelper.percentage(value, transactions)}
      end
    end
  end
end
