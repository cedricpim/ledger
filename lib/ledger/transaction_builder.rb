module Ledger
  # Class holding all the logic to build a new transaction. Since a transaction
  # is composed by many attributes, readline library is used to read each of the
  # inputs and build the transaction. A couple of improvements have been added
  # such as default attributes and auto-complete.
  class TransactionBuilder
    DEFAULT = ''.freeze
    AUTO_COMPLETE = %i[account category description venue currency travel].freeze
    ALLOWED_DATE_SEPARATORS = %r{-|/|\.}

    attr_reader :repository, :options

    def initialize(repository, options)
      @repository = repository
      @options = options
    end

    def build!
      CONFIG.fields.each_with_index do |(field, default_options), index|
        read(field, index, default_options)
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

    def read(key, index, default: DEFAULT, presence: false, values: [])
      title = key.to_s.capitalize

      value = provided_values[index] || handle_input(key, title, default, values)

      puts "#{title} must be present" or exit if presence && value.empty?

      transaction.public_send(:"#{key}=", value)
    end

    def handle_input(key, title, default, values)
      prepare_readline_completion(key, values)

      value = Readline.readline("#{title} [#{default}] ", true).strip
      process_input(key, default, value)
    end

    def process_input(key, default, value)
      return default if value.empty?
      return value if key != :date

      value = Array.new(3) do |i|
        value.split(ALLOWED_DATE_SEPARATORS)[i] || default.split(ALLOWED_DATE_SEPARATORS)[i]
      end.join('-')

      Date.parse(value) && value
    end

    # Include values on the list
    def prepare_readline_completion(key, values)
      completion_list = (AUTO_COMPLETE.include?(key) ? collect_values(key) : []).concat(values).uniq.sort

      Readline.completion_proc = completion_list && proc do |s|
        completion_list.grep(/^#{Regexp.escape(s)}/i)
      end
    end

    def collect_values(key)
      repository.transactions.map(&key).uniq.compact.sort
    end

    def provided_values
      options[:transaction].to_a
    end
  end
end
