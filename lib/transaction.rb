# Class representing a single transaction, it contains also some methods
# related to printing the information to different sources.
# The class is modeled by the fields defined on the configuration file.
Transaction = Struct.new(*CONFIGS[:fields].keys) do # rubocop:disable Metrics/BlockLength
  attr_writer :money

  def parsed_date
    @parsed_date ||= date.is_a?(String) ? Date.parse(date) : date
  end

  def expense?
    money.negative?
  end

  def processed?
    processed == 'yes'
  end

  def money
    @money ||= Money.new(BigDecimal(amount) * currency_info.subunit_to_unit, currency_info)
  end

  def ledger_format(member)
    value = public_send(member)

    case member
    when :amount    then money.format(CONFIGS[:money][:ledger])
    when :currency  then money.currency.iso_code
    else value
    end
  end

  def to_ledger
    members.map { |member| ledger_format(member) }.join(',') + "\n"
  end

  # Move format to configuration?
  def to_s(display_travel: true)
    amount = money.format(CONFIGS[:money][:display])
    processed = processed? ? '✓' : '×'
    message = "#{processed} [#{account}] Date: #{date}, #{category} (#{description}), #{amount}"
    display_travel && travel ? "#{message}, Travel: #{travel}" : message
  end

  private

  def currency_info
    @currency_info ||= Money::Currency.new(currency)
  end
end
