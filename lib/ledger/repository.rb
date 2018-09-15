module Ledger
  # Class responsible for reading the ledger file into memory and loading all the
  # transactions, creating the ledger file or adding a new transaction.
  class Repository
    extend Forwardable

    class IncorrectCSVFormatError < StandardError; end

    # Methods that are forwarded to content
    CONTENT_METHODS = %i[
      transactions accounts currencies current
      trips reports analysis comparisons
      accounts_currency filtered_transactions excluded_transactions periods
    ].freeze

    def_delegators :content, *CONTENT_METHODS

    attr_reader :current_transactions, :options
    attr_accessor :counter

    def initialize(options = {})
      @current_transactions = []
      @options = options
      @counter = 1
    end

    def load!
      encryption.wrap { |file| parse(file) }
    end

    def book!
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
      line = ":#{options[:line]}" if options[:line]
      encryption.wrap { |file| system("#{ENV['EDITOR']} #{file.path}#{line}") }
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

    def parse(file)
      CSV.foreach(file, headers: true, header_converters: :symbol) do |row|
        self.counter += 1
        current_transactions << Transaction.new(row.to_h)
      end
    rescue OpenSSL::Cipher::CipherError => e
      raise e
    rescue StandardError
      raise IncorrectCSVFormatError, "A problem reading line #{counter} has occurred"
    end
  end
end
