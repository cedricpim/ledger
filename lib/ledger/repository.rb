module Ledger
  # Class responsible for reading the ledger file into memory and loading all the
  # transactions, creating the ledger file or adding a new transaction.
  class Repository
    extend Forwardable

    # Methods that are forwarded to content
    CONTENT_METHODS = %i[
      transactions accounts currencies current
      trips reports studies comparisons
      accounts_currency filtered_transactions excluded_transactions periods
    ].freeze

    def_delegators :content, *CONTENT_METHODS

    attr_reader :current_transactions, :options

    def initialize(options = {})
      @current_transactions = []
      @options = options
    end

    def load!
      encryption.wrap do |file|
        CSV.foreach(file, headers: true, header_converters: :symbol) do |row|
          current_transactions << Transaction.new(row.to_h)
        end
      end
    end

    def add!
      transaction = TransactionBuilder.new(self).build!

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
      @content ||= begin
        load!
        Content.new(current_transactions, options)
      end
    end
  end
end
