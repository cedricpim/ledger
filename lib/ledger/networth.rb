module Ledger
  # Class representing the net worth on a given date. It also contains some
  # methods related to print the information to different sources.
  Networth = Struct.new(:date, :amount, :currency, keyword_init: true) do
    attr_writer :money

    def parsed_date
      @parsed_date ||= date.is_a?(String) ? Date.parse(date) : date
    end

    def money
      @money ||= Money.new(BigDecimal(amount) * currency_info.subunit_to_unit, currency_info)
    end

    def to_file
      members.map { |member| ledger_format(member) }.join(',') + "\n"
    end

    def exchange_to(currency)
      dup.tap do |networth|
        networth.money = money.exchange_to(currency)
        networth.amount = MoneyHelper.display(networth.money, type: :ledger)
        networth.currency = networth.money.currency.iso_code
      end
    end

    private

    def ledger_format(member)
      value = public_send(member)

      case member
      when :amount   then MoneyHelper.display(money, type: :ledger)
      when :currency then money.currency.iso_code
      else value
      end
    end

    def currency_info
      @currency_info ||= Money::Currency.new(currency)
    end
  end
end
