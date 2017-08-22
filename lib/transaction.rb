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
Transaction = Struct.new(:account, :date, :category, :description, :amount, :currency, :travel) do
  def initialize(*)
    super
    self.date = date
    self.amount = amount
  end

  def date=(date)
    self['date'] = Utils.cast(date, Date)
  end

  def amount=(amount)
    self['amount'] = Utils.cast(amount, BigDecimal)
  end

  def expense?
    amount.negative?
  end

  def ledger_format(member)
    value = public_send(member)

    case member
    when :date then value.strftime('%d-%m-%Y')
    when :amount then value.to_f
    when :account then value.code
    else value
    end
  end

  def to_ledger
    members.map { |member| ledger_format(member) }.join(',') + "\n"
  end

  def to_s(display_travel: true)
    amount = expense? ? ledger_format(:amount) : "+#{ledger_format(:amount)}"
    message = "[#{ledger_format(:account)}] Date: #{ledger_format(:date)}, #{category} (#{description}), #{amount}#{currency}"
    display_travel && travel ? "#{message}, Travel: #{travel}" : message
  end
end
