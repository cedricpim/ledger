module Ledger
  # Module containing helpers to deal with Money instances.
  module MoneyHelper
    class << self
      def display(money)
        return CONFIG.output(:default, :money) unless money.is_a?(Money)

        money.format(CONFIG.money_format(type: :display))
      end

      def percentage(value, transactions = [], &block)
        value, total = percentage_values(value, transactions, &block)

        return CONFIG.output(:default, :percentage) unless total.is_a?(Money) && value.is_a?(Money)

        ((value.abs / total.abs) * 100).to_f.round(2)
      end

      def color(value)
        key =
          case
          when value.negative? then :negative
          when value.positive? then :positive
          else :neutral
          end

        CONFIG.output(:color, :money, key)
      end

      private

      def percentage_values(value, transactions)
        return unless value.is_a?(Money)

        if block_given?
          [value, yield]
        else
          filter = value.negative? ? :expense? : :income?
          [value, transactions.select(&filter).sum(&:money)]
        end
      end
    end
  end
end
