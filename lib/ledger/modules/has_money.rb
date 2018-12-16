module Ledger
  # Module responsible for encapsulating other modules that contain shared
  # behaviour.
  module Modules
    # Module responsible for holding behaviour regarding classes that have an
    # amount and a currency and use Money.
    module HasMoney
      attr_writer :money, :valuation

      def money
        @money ||= Money.new(BigDecimal(amount) * currency_info.subunit_to_unit, currency_info)
      end

      def valuation
        @valuation ||= Money.new(BigDecimal(investment) * currency_info.subunit_to_unit, currency_info)
      end

      def expense?
        money.negative?
      end

      def income?
        !expense?
      end

      def to_file
        members.map { |member| ledger_format(member) }.join(',')
      end

      def exchange_to(currency)
        dup.tap do |networth|
          networth.money = money.exchange_to(currency)
          networth.amount = MoneyHelper.display(networth.money, type: :ledger)
          networth.currency = networth.money.currency.iso_code

          if networth.respond_to?(:investment)
            networth.valuation = valuation.exchange_to(currency)
            networth.investment = MoneyHelper.display(networth.valuation, type: :ledger)
          end
        end
      end

      private

      def ledger_format(member)
        value = public_send(member)

        case member
        when :amount     then MoneyHelper.display(money, type: :ledger)
        when :investment then MoneyHelper.display(valuation, type: :ledger)
        when :currency   then money.currency.iso_code
        else value
        end
      end

      def currency_info
        @currency_info ||= Money::Currency.new(currency)
      end
    end
  end
end
