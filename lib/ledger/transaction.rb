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

  def to_ledger
    members.map { |member| ledger_format(member) }.join(',') + "\n"
  end

  def to_s
    format(CONFIG.template(:transaction), attributes.merge(travel: travel && ", Travel: #{travel}"))
  end

  def attributes
    templates = CONFIG.templates(:fields)

    members.zip(values).to_h.merge(
      date: parsed_date.strftime(templates.dig(:date)),
      money: MoneyHelper.display(money),
      processed: templates.dig(:processed, processed)
    )
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
