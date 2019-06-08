require_relative 'transaction'
require_relative 'networth'

module Ledger
  # Class responsible for reading the ledger file into memory and loading all the
  # transactions, creating the ledger file or adding a new transaction.
  class Repository
    extend Forwardable

    class IncorrectCSVFormatError < StandardError; end

    # Map of which type of file has which entity
    ENTITIES = {
      ledger: Ledger::Transaction,
      networth: Ledger::Networth
    }.freeze

    # Methods that are forwarded to content
    CONTENT_METHODS = %i[
      transactions accounts currencies current trips reports analyses
      comparisons accounts_currency filtered_transactions
      excluded_transactions periods
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

    def add(*entries, type: :ledger, reset: false)
      open(type) do |file|
        file.seek(0, reset ? IO::SEEK_SET : IO::SEEK_END)
        file.puts(headers(type)) if reset
        entries.flatten.compact.each { |entry| file.puts(entry.to_file) }
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
      csv = CSV.new(file, headers: true, header_converters: :symbol).to_enum.with_index(1)

      Enumerator.new { |yielder| iterator(yielder, csv, resource: resource) }
    end

    def iterator(yielder, csv, resource:)
      while (elem, index = csv.next)
        raise IncorrectCSVFormatError, "A problem reading line #{index + 1} has occurred" if elem.headers.include?(nil)

        yielder.yield ENTITIES[resource].new(elem.to_h)
      end
    rescue StopIteration
      csv.tap(&:rewind)
    end

    def content
      @content ||= Content.new(load(:ledger), options)
    end
  end
end
