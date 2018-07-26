module Ledger
  # Module containing helpers to deal with Money instances and values representation.
  module MoneyHelper
    class << self
      def display(money, type: :display)
        return CONFIG.default_value unless money.is_a?(Money)

        money.format(CONFIG.money_format(type: type))
      end

      def percentage(value, transactions = [], &block)
        value, total = percentage_values(value, transactions, &block)

        return CONFIG.default_value unless total.is_a?(Money) && value.is_a?(Money)

        ((value.abs / total.abs) * 100).to_f.round(2)
      end

      def display_with_percentage(*transactions, &block)
        value = transactions.shift.sum(&:money)

        if block_given?
          [display(value), percentage(value, &block)]
        else
          [display(value)].concat(transactions.map { |ts| percentage(value, ts) })
        end
      end

      def display_with_color(value, options = {})
        display, color =
          if value.is_a?(Money)
            [display(value), color(value)]
          elsif value
            ["#{value}%", color(value)]
          else
            [CONFIG.default_value, color(0)]
          end

        [display.start_with?('-', '+') ? display[1..-1] : display, options.merge(color)]
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
