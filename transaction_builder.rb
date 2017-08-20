# Class holding all the logic to build a new transaction. Since a transaction
# is composed by many attributes, readline library is used to read each of the
# inputs and build the transaction. A couple of improvements have been added
# such as default attributes and auto-complete.
class TransactionBuilder
  WITH_SIGN = /^(-|\+)/.freeze

  attr_reader :ledger, :transaction

  def initialize(ledger)
    @ledger = ledger
    @transaction = default_transaction
  end

  def build!
    read_account
    read(:date, default: transaction.ledger_format(:date))
    read(:category, presence: true)
    read(:description)
    read(:amount, presence: true) { |value| value =~ WITH_SIGN ? value : "-#{value}" }
    read(:currency)
    read(:travel)

    transaction
  end

  private

  def default_transaction
    Transaction.new(
      ledger.accounts[DEFAULT_ACCOUNT_CODE],
      DEFAULT_DATE,
      DEFAULT_CATEGORY,
      DEFAULT_DESCRIPTION,
      DEFAULT_AMOUNT,
      DEFAULT_CURRENCY,
      DEFAULT_TRAVEL
    )
  end

  private

  def read_account
    read(:account, default: transaction.ledger_format(:account)) do |value|
      ledger.accounts[value].tap do |account|
        fail ArgumentError, "Account must be present" if account.nil? && !value.empty?
      end
    end
  end

  def read(key, default: transaction.public_send(key), presence: false)
    title = key.to_s.sub('_', ' ').capitalize

    prepare_readline_completion(key)
    value = Readline.readline("#{title} [#{default}] ", true)

    fail ArgumentError, "#{title} must be present" if presence && value.empty?

    value = yield(value) if block_given?

    transaction.public_send(:"#{key}=", value) unless (value.respond_to?(:empty?) && value.empty?) || value.nil?
  end

  def prepare_readline_completion(key)
    completion_list =
      case key
      when :account     then ledger.accounts.keys
      when :category    then (DEFAULT_CATEGORIES_LIST + ledger.existing_categories).uniq.sort
      when :description then ledger.existing_descriptions
      when :currency    then (DEFAULT_CURRENCIES_LIST + ledger.existing_currencies).uniq.sort
      when :travel      then ledger.existing_travels
      end

    Readline.completion_proc = completion_list && proc { |s| completion_list.grep(/^#{Regexp.escape(s)}/) }
  end
end
