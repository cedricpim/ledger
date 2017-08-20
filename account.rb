# Encapsulates any type of account, present on the first lines of the Ledger.
#
# code: identifier of the account
# name: name of the account
# amount: current balance
# currency: currency of the account
Account = Struct.new(:code, :name, :amount, :currency) do
  def initialize(*)
    super
    self.amount = amount
  end

  def amount=(amount)
    self['amount'] = Utils.cast(amount, BigDecimal)
  end

  def to_s
    "#{name} - #{amount.to_f}#{currency}"
  end
end
