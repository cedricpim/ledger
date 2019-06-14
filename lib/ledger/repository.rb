require_relative 'transaction'
require_relative 'networth'

module Ledger
  # Class responsible for reading the ledger file into memory and loading all the
  # transactions, creating the ledger file or adding a new transaction.
  class Repository
    extend Forwardable

    class LineError < StandardError; end

    # Map of which type of file has which entity
    ENTITIES = {
      ledger: Ledger::Transaction,
      networth: Ledger::Networth
    }.freeze

    # Methods that are forwarded to content
    CONTENT_METHODS = %i[
      transactions accounts currencies current trips accounts_currency filtered_transactions
    ].freeze

    def_delegators :content, *CONTENT_METHODS

    attr_reader :options, :encryption

    def initialize(options = {})
      @options = options
      @encryption = {
        ledger: Encryption.new(CONFIG.ledger),
        networth: Encryption.new(CONFIG.networth)
      }
    end

    def add(*entries, resource: :ledger, reset: false)
      open(resource) do |file|
        file.seek(0, reset ? IO::SEEK_SET : IO::SEEK_END)
        file.puts(headers(resource)) if reset
        entries.flatten.compact.each { |entry| file.puts(entry.to_file) }
        file.truncate(file.pos)
        file.rewind
      end
    end

    def load(resource)
      open(resource) { |file| parse(file, resource: resource) }
    end

    def open(resource, &block)
      encryption[resource].wrap(&block)
    end

    private

    def headers(type)
      ENTITIES[type].members.map(&:capitalize).join(",")
    end

    # @note index starts at 1, since the first line is the header
    def parse(file, resource: :ledger)
      csv = CSV.new(file, headers: true, header_converters: :symbol, nil_value: '').to_enum.with_index(1)

      Enumerator.new { |yielder| iterator(yielder, csv, resource: resource) }
    end

    def iterator(yielder, csv, resource:)
      while (elem, index = csv.next)
        yielder.yield ENTITIES[resource].new(elem.to_h).tap(&:validate!)
      end
    rescue StopIteration
      csv.tap(&:rewind)
    rescue LineError => e
      raise e.class, e.message + " (Line #{index + 1})"
    rescue CSV::MalformedCSVError => e
      raise OpenSSL::Cipher::CipherError, e.message
    end

    def content
      @content ||= Content.new(load(:ledger), options)
    end
  end
end
