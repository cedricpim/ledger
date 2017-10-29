# Class holding all the logic to build a new transaction. Since a transaction
# is composed by many attributes, readline library is used to read each of the
# inputs and build the transaction. A couple of improvements have been added
# such as default attributes and auto-complete.
class TransactionBuilder
  DEFAULT = ''.freeze
  AUTO_COMPLETE = %i[account category description currency travel].freeze

  attr_reader :repository

  def initialize(repository)
    @repository = repository
  end

  def build!(params)
    CONFIG.fields.each_with_index do |(field, options), index|
      read(field, params.to_a[index], options)
    end

    exchange_money

    transaction
  rescue Exception => e # rubocop:disable Lint/RescueException
    puts e.message or exit
  end

  private

  def transaction
    @transaction ||= Transaction.new
  end

  def exchange_money
    account_currency = repository.accounts_currency[transaction.account]

    return unless account_currency

    transaction.money = transaction.money.exchange_to(account_currency)
  end

  def read(key, value, default: DEFAULT, presence: false, values: [])
    title = key.to_s.capitalize

    value ||= handle_input(key, title, default, values)

    puts "#{title} must be present" or exit if presence && value.empty?

    transaction.public_send(:"#{key}=", value)
  end

  def handle_input(key, title, default, values)
    prepare_readline_completion(key, values)

    value = Readline.readline("#{title} [#{default}] ", true).strip
    value.empty? ? default : value
  end

  # Include values on the list
  def prepare_readline_completion(key, values)
    completion_list = (AUTO_COMPLETE.include?(key) ? collect_values(key) : []).concat(values).uniq.sort

    Readline.completion_proc = completion_list && proc do |s|
      completion_list.grep(/^#{Regexp.escape(s)}/i)
    end
  end

  def collect_values(key)
    repository.list.map(&key).uniq.compact.sort
  end
end
