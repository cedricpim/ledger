# Class holding all the logic to build a new transaction. Since a transaction
# is composed by many attributes, readline library is used to read each of the
# inputs and build the transaction. A couple of improvements have been added
# such as default attributes and auto-complete.
class TransactionBuilder
  attr_reader :ledger, :transaction

  def initialize(ledger)
    @ledger = ledger
    @transaction = default_transaction
  end

  def build!
    read(:account)
    read(:date, default: transaction.ledger_format(:date))
    read(:category, presence: true)
    read(:description)
    read(:amount, presence: true)
    read(:currency)
    read(:travel)
    read(:processed, default: transaction.ledger_format(:processed))

    exchange_money

    transaction
  end

  private

  def exchange_money
    account_currency = ledger.currency_per_account[transaction.account]

    return unless account_currency

    transaction.money = transaction.money.exchange_to(account_currency)
  end

  def read(key, default: transaction.public_send(key), presence: false)
    title = key.to_s.capitalize

    prepare_readline_completion(key)
    value = Readline.readline("#{title} [#{default}] ", true).strip

    fail ArgumentError, "#{title} must be present" if presence && value.empty?

    transaction.public_send(:"#{key}=", value.empty? ? default : value)
  end

  def prepare_readline_completion(key)
    completion_list =
      case key
      when :account     then ledger.accounts
      when :category    then (CONFIGS[:currencies] + ledger.categories).uniq.sort
      when :description then ledger.descriptions
      when :currency    then (CONFIGS[:categories] + ledger.currencies).uniq.sort
      when :travel      then ledger.travels
      when :processed   then CONFIGS[:values].values
      end

    Readline.completion_proc = completion_list && proc { |s| completion_list.grep(/^#{Regexp.escape(s)}/i) }
  end

  def default_transaction
    Transaction.new(*CONFIGS[:fields].values)
  end
end
