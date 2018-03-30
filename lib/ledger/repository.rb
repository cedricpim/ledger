module Ledger
  # Class responsible for reading the ledger file into memory and loading all the
  # transactions, creating the ledger file or adding a new transaction.
  class Repository
    extend Forwardable

    def_delegators :content, :transactions, :accounts, :categories, :currencies, :current,
                   :descriptions, :travels, :trips, :report, :study, :accounts_currency,
                   :filtered_transactions, :excluded_transactions

    attr_reader :current_transactions, :options

    def initialize(options = {})
      @current_transactions = []
      @options = options
    end

    def load!
      encryption.wrap do |file|
        CSV.foreach(file, headers: true) do |row|
          current_transactions << Transaction.new(*row.fields)
        end
      end
    end

    def add!
      transaction = TransactionBuilder.new(self, options).build!

      encryption.wrap do |file|
        File.open(file, 'a') { |f| f.write("#{transaction.to_ledger}\n") }
        File.write(file, File.read(file).gsub(/\n+/, "\n"))
      end
    end

    def create!
      filepath = File.expand_path(CONFIG.ledger)

      return if File.exist?(filepath)

      CSV.open(filepath, 'wb') { |csv| csv << CONFIG.transaction_fields.map(&:capitalize) }

      encryption.encrypt!
    end

    def edit!
      encryption.wrap { |file| system("#{ENV['EDITOR']} #{file.path}") }
    end

    private

    def encryption
      @encryption ||= Encryption.new
    end

    def content
      return @content if @content

      load!

      @content = Content.new(current_transactions, options)
    end
  end
end
