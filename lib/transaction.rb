# Class representing a single transaction, it contains also some methods
# related to printing the information to different sources.
#
# account: account where this transaction was made
# date: date of the transaction
# category: category of the transaction
# description: description of the transaction
# amount: value of the transaction (marked with -/+ to identify an expense vs an income)
# currency: currency on which the transaction was made
# travel: string identifying a transaction made on the context of a trip
# processed: string identifying if a transaction has been processed or not
Transaction = Struct.new(:account, :date, :category, :description, :amount, :currency, :travel, :processed) do
  alias_method :processed?, :processed

  attr_writer :money

  def initialize(*)
    super
    self.date = date
    self.processed = processed
  end

  def date=(date)
    self['date'] = date.is_a?(String) ? Date.parse(date) : date
  end

  def processed=(processed)
    self['processed'] = !processed.nil? && processed.to_sym == CONFIGS[:values][:true]
  end

  def expense?
    money.negative?
  end

  def money
    @money ||= Money.new(BigDecimal(amount) * currency_info.subunit_to_unit, currency_info)
  end

  def ledger_format(member)
    value = public_send(member)

    case member
    when :date      then value.strftime(CONFIGS[:date][:format])
    when :amount    then money.format(CONFIGS[:money][:ledger])
    when :currency  then money.currency.iso_code
    when :processed then (processed? ? CONFIGS[:values][:true] : CONFIGS[:values][:false])
    else value
    end
  end

  def to_ledger
    members.map { |member| ledger_format(member) }.join(',') + "\n"
  end

  def to_s(display_travel: true)
    amount = money.format(CONFIGS[:money][:display])
    processed = processed? ? '✓' : '×'
    message = "#{processed} [#{account}] Date: #{ledger_format(:date)}, #{category} (#{description}), #{amount}"
    display_travel && travel ? "#{message}, Travel: #{travel}" : message
  end

  private

  def currency_info
    @currency_info ||= Money::Currency.new(currency)
  end
end
