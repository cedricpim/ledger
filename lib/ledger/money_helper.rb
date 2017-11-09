module Ledger
  # Module containing helpers to deal with Money instances.
  module MoneyHelper
    class << self
      def display(money)
        return CONFIG.output(:default, :money) unless money.is_a?(Money)

        money.format(CONFIG.money_format(type: :display))
      end

      def balance(transactions, percentage_related = transactions, &block)
        [
          transactions.select(&:expense?).sum(&:money),
          transactions.select(&:income?).sum(&:money)
        ].map do |value|
          [display(value), percentage(value, percentage_related, &block)]
        end.flatten
      end

      def percentage(value, transactions = [], &block)
        value, total = percentage_values(value, transactions, &block)

        return CONFIG.output(:default, :percentage) unless total.is_a?(Money) && value.is_a?(Money)

        ((value.abs / total.abs) * 100).to_f.round(2)
      end

      private

      def percentage_values(value, transactions)
        return unless value.is_a?(Money)

        return yield(value) if block_given?

        filter = value.negative? ? :expense? : :income?
        [value, transactions.select(&filter).sum(&:money)]
      end
    end
  end
end
