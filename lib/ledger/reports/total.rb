module Ledger
  module Reports
    # Class responsible for generating the table with the total values for a
    # ledger, along with a comparison with the period values.
    # @note For the percentage, it calculates how much the difference between
    # income and expense impacts the current total value.
    class Total < Base
      def period
        @period ||= Period.new(options, ledger: ledger).period
      end

      def total
        @total ||= info { |currency| current.exchange_to(currency) }
      end

      private

      def filters(inverted:)
        [
          Filters::IncludeCategory.new(options, :report),
          Filters::IncludeAccount.new(options, :report),
          Filters::PresentCategory.new(options.merge(inverted: inverted)),
          Filters::Period.new(options)
        ]
      end

      def filtered
        @filtered ||= Filter.new(ledger, filters: filters(inverted: false), currency: currency).call
      end

      def excluded
        @excluded ||= Filter.new(ledger, filters: filters(inverted: true), currency: currency).call
      end

      def income
        @income ||= begin
          value = calculate(:income?, :expense?)
          value.positive? ? value : Money.new(0, currency)
        end
      end

      def expense
        @expense ||= begin
          value = calculate(:expense?, :income?)
          value.negative? ? value : Money.new(0, currency)
        end
      end

      def info
        return {} if ledger.empty?

        {values: currencies.map { |currency| yield currency }, percentage: percentage}
      end

      def calculate(filtered_method, excluded_method)
        filtered.select(&filtered_method).sum(&:money) + excluded.select(&excluded_method).sum(&:money)
      end

      def percentage
        return percentage_extremes if percentage_extremes

        (percentage_value * 100).round(2).abs * (difference.positive? ? 1 : -1)
      end

      def percentage_value
        difference / (current - difference)
      end

      def difference
        income - expense.abs
      end

      def percentage_extremes
        @percentage_extremes ||=
          if income.zero? && expense.zero?
            BigDecimal::NAN
          elsif income.zero?
            -BigDecimal::INFINITY
          elsif expense.zero?
            BigDecimal::INFINITY
          end
      end

      def currency
        CONFIG.default_currency
      end

      def current
        @current ||= balances.sum { |balance| balance.exchange_to(currency) }
      end

      def currencies
        @currencies ||= balances.map { |balance| balance.currency.iso_code }.uniq.sort
      end

      def balances
        @balances ||= Balance.new(ledger: ledger).data.map do |title:, value:|
          value if value && Filters::IncludeAccount.new({}, :report).call(Transaction.new(account: title))
        end.compact
      end
    end
  end
end
