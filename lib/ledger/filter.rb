module Ledger
  # Class responsible for applying each of the received filters to the list of
  # entries given.
  class Filter
    attr_reader :entries, :filters, :currency

    def initialize(entries, filters:, currency: nil)
      @entries = entries
      @filters = filters
      @currency = currency
    end

    def call
      filtered = entries.select do |entry|
        filters.all? do |filter|
          selected = filter.call(entry)

          (!filter.inverted? && selected) || (filter.inverted? && !selected)
        end
      end

      return filtered unless currency

      filtered.map { |entry| currency ? entry.exchange_to(currency) : entry }
    end
  end
end
