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

    def_delegators :content, *CONTENT_METHODS

    attr_reader :options, :entries, :encryption

    def initialize(options = {})
      @options = options
      @entries = {
        ledger: [],
        networth: []
      }
      @encryption = {
        ledger: Encryption.new(CONFIG.ledger),
        networth: Encryption.new(CONFIG.networth)
      }
    end

    def add(*entries, type: :ledger, reset: false)
      open(type) do |file|
        file.seek(0, reset ? IO::SEEK_SET : IO::SEEK_END)
        file.puts(headers(type)) if reset
        entries.flatten.compact.each { |entry| file.puts(entry.to_file) }
        file.rewind
      end
    end

    def open(resource, &block)
      encryption[resource].wrap(&block)
    end

    def load(resource, &block)
      encryption[resource].wrap { |file| parse(file, resource: resource, &block) }
    end

    private

    def headers(type)
      Object.const_get(ENTITIES[type]).members.map(&:capitalize).join(",")
    end

    # @note index starts at 2, since the file lines start at 1, and the first line is the header
    def parse(file, resource: :ledger, &block)
      CSV.new(file, headers: true, header_converters: :symbol).each.with_index(2) do |row, index|
        load_entry(row.to_h, index, resource: resource, &block)
      end
    rescue OpenSSL::Cipher::CipherError => e
      raise e
    end

    def load_entry(attributes, index, resource:, &block)
      entry = Object.const_get(ENTITIES[resource]).new(attributes)
      block ? block.call(entry) : entries[resource] << entry
    rescue StandardError
      raise IncorrectCSVFormatError, "A problem reading line #{index} has occurred"
    end

    def content
      @content ||= load! { Content.new(entries[:ledger], options) }
    end

    def load!
      Encryption.new(CONFIG.ledger).wrap { |file| parse(file, resource: :ledger) }
      Encryption.new(CONFIG.networth).wrap { |file| parse(file, resource: :networth) }
      yield if block_given?
    end
  end
end
