module Ledger
  # Module responsible for encapsulating other modules that contain shared
  # behaviour.
  module Modules
    # Module responsible for holding behaviour regarding classes that have an
    # amount and a currency and use Money.
    module HasMoney
      attr_writer :money, :valuation, :day_investment

      MAPPED_FIELDS = {amount: :money, investment: :valuation, invested: :day_investment}.freeze

      def money
        @money ||= Money.new(BigDecimal(amount.to_s) * currency_info.subunit_to_unit, currency_info)
      rescue ArgumentError, TypeError
        nil
      end

      def valuation
        @valuation ||= Money.new(BigDecimal(investment.to_s) * currency_info.subunit_to_unit, currency_info)
      rescue ArgumentError, TypeError
        nil
      end

      def day_investment
        @day_investment ||= Money.new(BigDecimal(invested.to_s) * currency_info.subunit_to_unit, currency_info)
      rescue ArgumentError, TypeError
        nil
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
        dup.tap do |entity|
          MAPPED_FIELDS.each do |field, representation|
            next unless entity.respond_to?(field)

            entity.public_send(:"#{representation}=", public_send(representation).exchange_to(currency))
            entity.public_send(:"#{field}=", MoneyHelper.display(entity.public_send(representation), type: :ledger))
          end

          entity.currency = entity.money.currency.iso_code
        end
      end

      private

      def ledger_format(member)
        value = public_send(member)

        case member
        when :amount     then MoneyHelper.display(money, type: :ledger)
        when :investment then MoneyHelper.display(valuation, type: :ledger)
        when :invested   then MoneyHelper.display(day_investment, type: :ledger)
        when :currency   then money && money&.currency&.iso_code
        else value
        end
      end

      def currency_info
        @currency_info ||= Money::Currency.new(currency)
      end
    end
  end
end
