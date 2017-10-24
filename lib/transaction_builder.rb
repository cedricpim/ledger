# Class holding all the logic to build a new transaction. Since a transaction
# is composed by many attributes, readline library is used to read each of the
# inputs and build the transaction. A couple of improvements have been added
# such as default attributes and auto-complete.
class TransactionBuilder
  attr_reader :ledger

  def initialize(ledger)
    @ledger = ledger
  end

  def build!
    CONFIGS[:fields].each { |field, options| read(field, options) }

    exchange_money

    transaction
  end

  private

  def transaction
    @transaction ||= Transaction.new
  end

  def exchange_money
    account_currency = ledger.accounts_currency[transaction.account]

    return unless account_currency

    transaction.money = transaction.money.exchange_to(account_currency)
  end

  def read(key, default: '', presence: false, values: [])
    title = key.to_s.capitalize

    prepare_readline_completion(key, values)
    value = treat_input(title, default)

    puts "#{title} must be present" or exit if presence && value.empty?

    transaction.public_send(:"#{key}=", value)
  end

  def treat_input(title, default)
    value = Readline.readline("#{title} [#{default}] ", true).strip
    value.empty? ? default : value
  end

  # Include values on the list
  def prepare_readline_completion(key, values)
    completion_list = recommendations(key).concat(values).uniq.sort

    Readline.completion_proc = completion_list && proc do |s|
      completion_list.grep(/^#{Regexp.escape(s)}/i)
    end
  end

  def recommendations(key)
    case key
    when :account     then ledger.accounts
    when :category    then ledger.categories
    when :description then ledger.descriptions
    when :currency    then ledger.currencies
    when :travel      then ledger.travels
    else []
    end
  end
end
