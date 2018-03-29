module Ledger
  # Class representing a single transaction, it contains also some methods
  # related to printing the information to different sources.
  # The class is modeled by the fields defined on the configuration file.
  Transaction = Struct.new(*CONFIG.transaction_fields) do # rubocop:disable Metrics/BlockLength
    attr_writer :money

    WITH_SIGNAL = /\+|\-/

    def amount=(amount)
      self['amount'] = amount.nil? || amount.match?(WITH_SIGNAL) ? amount : "-#{amount}"
    end

    def parsed_date
      @parsed_date ||= date.is_a?(String) ? Date.parse(date) : date
    end

    def money
      @money ||= Money.new(BigDecimal(amount) * currency_info.subunit_to_unit, currency_info)
    end

    def expense?
      money.negative?
    end

    def income?
      !expense?
    end

    def to_ledger
      members.map { |member| ledger_format(member) }.join(',') + "\n"
    end

    def details(include_account: false, percentage_related_to: [])
      percentage = MoneyHelper.percentage(money, percentage_related_to)

      [date, category, MoneyHelper.display(money), percentage].tap do |values|
        values.unshift(account) if include_account
      end
    end

    def exchange_to(currency)
      dup.tap { |transaction| transaction.money = money.exchange_to(currency) }
    end

    private

    def ledger_format(member)
      value = public_send(member)

      case member
      when :amount   then money.format(CONFIG.money_format(type: :ledger))
      when :currency then money.currency.iso_code
      else value
      end
    end

    def currency_info
      @currency_info ||= Money::Currency.new(currency)
    end
  end
end
