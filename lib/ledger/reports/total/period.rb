require 'ledger/reports/total'

module Ledger
  module Reports
    class Total
      # Class responsible for generating the table with the total values for a
      # period, along with a comparison to the current values.
      # @note Since this is a tool to track expenses, we calculate the period
      # percentage in relation to the income. Therefore, -100% is when the
      # expense was the same as the income and 100% is when there was no expense.
      # So it goes from 100%..-Infinity (there are NaN and Infinity for extreme
      # cases).
      class Period < Total
        def period
          @period ||= info { |currency| {income: income.exchange_to(currency), expense: expense.exchange_to(currency)} }
        end

        private

        def percentage_value
          if income.zero? && expense.zero?
            BigDecimal::NAN
          elsif income.zero?
            -BigDecimal::INFINITY
          elsif expense.zero?
            BigDecimal::INFINITY
          else
            formula
          end
        end

        def formula
          difference.positive? ? 1 - (expense / income).abs : (expense / income)
        end
      end
    end
  end
end
