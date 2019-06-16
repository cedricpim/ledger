module Ledger
  module Actions
    class Book
      # Class holding all the logic to build a new transaction. Since a transaction
      # is composed by many attributes, readline library is used to read each of the
      # inputs and build the transaction. A couple of improvements have been added
      # such as default attributes and auto-complete.
      class Transaction
        DEFAULT = ''.freeze
        ALLOWED_DATE_SEPARATORS = %r{-|/|\.}.freeze

        attr_reader :values

        def initialize(values: [])
          @values = Array(values)
        end

        def build!
          CONFIG.fields.each_with_index do |(field, default_options), index|
            read(field, index, default_options)
          end

          transaction
        rescue Exception => e # rubocop:disable Lint/RescueException
          puts e.message or exit
        end

        private

        def transaction
          @transaction ||= Transaction.new
        end

        def read(key, index, default: DEFAULT, presence: false)
          title = key.to_s.capitalize

          value = values[index] || handle_input(key, title, default)

          puts "#{title} must be present" or exit if presence && value.empty?

          transaction.public_send(:"#{key}=", value)
        end

        def handle_input(key, title, default)
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
      end
    end
  end
end
