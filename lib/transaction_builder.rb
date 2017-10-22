# Class holding all the logic to build a new transaction. Since a transaction
# is composed by many attributes, readline library is used to read each of the
# inputs and build the transaction. A couple of improvements have been added
# such as default attributes and auto-complete.
class TransactionBuilder
  attr_reader :ledger, :transaction

  def initialize(ledger)
    @ledger = ledger
    @transaction = transaction
  end

  def build!
    read(:account)
    read(:date, default: transaction.ledger_format(:date))
    read(:category, presence: true)
    read(:description)
    read(:currency)
    read(:amount, presence: true)
    read(:travel)
    read(:processed, default: transaction.ledger_format(:processed))

    transaction
  end

  private

  def transaction
    Transaction.new(
      DEFAULT_ACCOUNT,
      DEFAULT_DATE,
      DEFAULT_CATEGORY,
      DEFAULT_DESCRIPTION,
      DEFAULT_AMOUNT,
      DEFAULT_CURRENCY,
      DEFAULT_TRAVEL,
      DEFAULT_PROCESSED
    )
  end

  def read(key, default: transaction.public_send(key), presence: false)
    title = key.to_s.capitalize

    prepare_readline_completion(key)
    value = Readline.readline("#{title} [#{default}] ", true)

    fail ArgumentError, "#{title} must be present" if presence && value.empty?

    transaction.public_send(:"#{key}=", value.empty? ? default : value)
  end

  def prepare_readline_completion(key)
    completion_list =
      case key
      when :account     then ledger.accounts
      when :category    then (DEFAULT_CATEGORIES_LIST + ledger.categories).uniq.sort
      when :description then ledger.descriptions
      when :currency    then (DEFAULT_CURRENCIES_LIST + ledger.currencies).uniq.sort
      when :travel      then ledger.travels
      when :processed   then [FALSE_VALUE, TRUE_VALUE]
      end

    Readline.completion_proc = completion_list && proc { |s| completion_list.grep(/^#{Regexp.escape(s)}/) }
  end
end
