module Ledger
  # Class responsible for reading the ledger file into memory and loading all the
  # transactions, creating the ledger file or adding a new transaction.
  class Repository
    extend Forwardable

    class IncorrectCSVFormatError < StandardError; end

    # Map of which type of file has which entity
    ENTITIES = {
      ledger: 'Ledger::Transaction',
      networth: 'Ledger::Networth'
    }.freeze

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

    attr_reader :transaction_entries, :networth_entries, :options, :encryption

    def initialize(options = {})
      @transaction_entries = []
      @networth_entries = []
      @options = options
      @encryption = {
        ledger: Encryption.new(CONFIG.ledger),
        networth: Encryption.new(CONFIG.networth)
      }
    end

    def add(*transactions, type: :ledger, reset: false)
      open(type) do |file|
        file.seek(0, reset ? IO::SEEK_SET : IO::SEEK_END)
        file.puts(headers(type)) if reset
        transactions.flatten.compact.each { |transaction| file.puts(transaction.to_file) }
        file.rewind
      end
    end

    def open(resource, &block)
      encryption[resource].wrap(&block)
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

    def headers(type)
      ENTITIES[type].constantize.members.map(&:capitalize).join(",")
    end

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
      CSV.new(file, headers: true, header_converters: :symbol).each.with_index(2) do |row, index|
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
