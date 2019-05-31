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

    def initialize(options = {})
      @transaction_entries = []
      @networth_entries = []
      @options = options
    end

    def add(transaction)
      Encryption.new(CONFIG.ledger).wrap do |file|
        file.seek(0, IO::SEEK_END)
        file.puts(transaction.to_file)
        file.rewind
      end
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
      current = current_networth

      Encryption.new(CONFIG.networth).wrap do |file|
        CSV.open(file, 'wb') { |csv| csv << Networth.members.map(&:capitalize) }

        networth_entries.each do |entry|
          entry.calculate_invested!(transaction_entries)

          save!(entry, file)
        end

        save!(current, file)
      end
    end

    def show
      (options[:networth] ? filtered_networth : filtered_transactions).each do |resource|
        system("echo \"#{resource.to_file}\" >> #{options[:output]}")
      end
    end

    private

    def resource
      options[:networth] ? CONFIG.networth : CONFIG.ledger
    end

    def content
      @content ||= load! { Content.new(transaction_entries, options) }
    end

    def networth_content
      @networth_content ||= load! { NetworthContent.new(networth_entries, options) }
    end

    def load!
      Encryption.new(CONFIG.ledger).wrap { |file| parse(file, networth: false) }
      Encryption.new(CONFIG.networth).wrap { |file| parse(file, networth: true) }
      yield if block_given?
    end

    # @note index starts at 2, since the file lines start at 1, and the first line is the header
    def parse(file, networth: false)
      CSV.foreach(file, headers: true, header_converters: :symbol).with_index(2) do |row, index|
        load_entry(row.to_h, index, networth: networth)
      end
    rescue OpenSSL::Cipher::CipherError => e
      raise e
    end

    def load_entry(attributes, index, networth: false)
      if networth
        networth_entries << Networth.new(attributes)
      else
        transaction_entries << Transaction.new(attributes)
      end
    rescue StandardError
      raise IncorrectCSVFormatError, "A problem reading line #{index} has occurred"
    end

    def save!(entity, file)
      File.open(file, 'a') { |f| f.write("#{entity.to_file}\n") }
      File.write(file, File.read(file).gsub(/\n+/, "\n"))
    end
  end
end
