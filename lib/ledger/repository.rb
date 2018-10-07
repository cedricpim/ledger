module Ledger
  # Class responsible for reading the ledger file into memory and loading all the
  # transactions, creating the ledger file or adding a new transaction.
  class Repository
    extend Forwardable

    class IncorrectCSVFormatError < StandardError; end

    # Methods that are forwarded to content
    CONTENT_METHODS = %i[
      transactions accounts currencies current
      trips reports analyses comparisons
      accounts_currency filtered_transactions excluded_transactions periods
    ].freeze

    # Methods that are forwarded to history
    HISTORY_METHODS = %i[filtered_networth].freeze

    def_delegators :content, *CONTENT_METHODS
    def_delegators :history, *HISTORY_METHODS

    attr_reader :transaction_entries, :networth_entries, :options
    attr_accessor :counter

    def initialize(options = {})
      @transaction_entries = []
      @networth_entries = []
      @options = options
      @counter = 1
    end

    def book!
      transaction = TransactionBuilder.new(self).build!

      encryption.wrap do |file|
        File.open(file, 'a') { |f| f.write("#{transaction.to_file}\n") }
        File.write(file, File.read(file).gsub(/\n+/, "\n"))
      end
    end

    def create!
      filepath = File.expand_path(networth? ? CONFIG.networth : CONFIG.ledger)

      return if File.exist?(filepath)

      CSV.open(filepath, 'wb') do |csv|
        csv << (networth? ? Networth.members : CONFIG.transaction_fields).map(&:capitalize)
      end

      encryption.encrypt!
    end

    def edit!
      line = ":#{options[:line]}" if options[:line]
      encryption.wrap { |file| system("#{ENV['EDITOR']} #{file.path}#{line}") }
    end

    def show
      resources = networth? ? filtered_networth : filtered_transactions
      system("echo \"#{resources.map(&:to_file).join}\" > #{options[:output]}")
    end

    private

    def encryption
      @encryption ||= Encryption.new(networth?)
    end

    def networth?
      options[:networth]
    end

    def content
      @content ||= load! { Content.new(transaction_entries, options) }
    end

    def history
      @history ||= load! { History.new(networth_entries, options) }
    end

    def load!
      encryption.wrap { |file| parse(file) }
      yield
    end

    def parse(file)
      CSV.foreach(file, headers: true, header_converters: :symbol) do |row|
        self.counter += 1
        if networth?
          networth_entries << Networth.new(row.to_h)
        else
          transaction_entries << Transaction.new(row.to_h)
        end
      end
    rescue OpenSSL::Cipher::CipherError => e
      raise e
    rescue StandardError
      raise IncorrectCSVFormatError, "A problem reading line #{counter} has occurred"
    end
  end
end
