module Ledger
  # Class responsible for reading the ledger file into memory and loading all the
  # transactions, creating the ledger file or adding a new transaction.
  class Repository
    extend Forwardable

    class IncorrectCSVFormatError < StandardError; end

    # Methods that are forwarded to content
    CONTENT_METHODS = %i[
      transactions accounts currencies current trips reports analyses
      comparisons accounts_currency filtered_transactions
      excluded_transactions periods current_networth
    ].freeze

    # Methods that are forwarded to networth content
    NETWORTH_CONTENT_METHODS = %i[filtered_networth].freeze

    def_delegators :content, *CONTENT_METHODS
    def_delegators :networth_content, *NETWORTH_CONTENT_METHODS

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

      Encryption.new(CONFIG.ledger).wrap { |file| save!(transaction, file) }
    end

    def convert!
      Encryption.new(CONFIG.ledger).wrap do |file|
        CSV.open(file, 'wb') { |csv| csv << CONFIG.transaction_fields.map(&:capitalize) }

        transactions.each do |transaction|
          exchanged = transaction.exchange_to(accounts_currency[transaction.account])
          save!(exchanged, file)
        end
      end
    end

    def create!
      filepath = File.expand_path(resource)

      return if File.exist?(filepath)

      CSV.open(filepath, 'wb') do |csv|
        csv << (options[:networth] ? Networth.members : CONFIG.transaction_fields).map(&:capitalize)
      end

      Encryption.new(resource).encrypt!
    end

    def edit!
      line = ":#{options[:line]}" if options[:line]
      Encryption.new(resource).wrap { |file| system("#{ENV['EDITOR']} #{file.path}#{line}") }
    end

    def networth!
      Encryption.new(CONFIG.networth).wrap { |file| save!(current_networth, file) }
    end

    def show
      resources = options[:networth] ? filtered_networth : filtered_transactions
      system("echo \"#{resources.map(&:to_file).join}\" > #{options[:output]}")
    end

    private

    def resource
      options[:networth] ? CONFIG.networth : CONFIG.ledger
    end

    def content
      @content ||= load!(CONFIG.ledger) { Content.new(transaction_entries, options) }
    end

    def networth_content
      @networth_content ||= load!(CONFIG.networth) { NetworthContent.new(networth_entries, options) }
    end

    def load!(filepath)
      Encryption.new(filepath).wrap { |file| parse(file) }
      yield if block_given?
    end

    def parse(file)
      CSV.foreach(file, headers: true, header_converters: :symbol) do |row|
        self.counter += 1
        load_entry(row.to_h)
      end
    rescue OpenSSL::Cipher::CipherError => e
      raise e
    end

    def load_entry(attributes)
      if options[:networth]
        networth_entries << Networth.new(attributes)
      else
        transaction_entries << Transaction.new(attributes)
      end
    rescue StandardError
      raise IncorrectCSVFormatError, "A problem reading line #{counter} has occurred"
    end

    def save!(entity, file)
      File.open(file, 'a') { |f| f.write("#{entity.to_file}\n") }
      File.write(file, File.read(file).gsub(/\n+/, "\n"))
    end
  end
end
