module Ledger
  # Class holding the networth entries read from the networth file and used to
  # query it.
  class History
    attr_reader :networth_entries, :options

    def initialize(networth_entries, options)
      @networth_entries = networth_entries.sort_by(&:parsed_date)
      @options = options
    end

    def filtered_networth
      @filtered_networth ||= exchanged_networth.select { |t| t.parsed_date.between?(*period) }
    end

    private

    def exchanged_networth
      @exchanged_networth = networth_entries.map do |networth_entry|
        currency ? networth_entry.exchange_to(currency) : networth_entry
      end
    end

    def period
      if filter_with_date_range?
        [options.fetch(:from, -Float::INFINITY), options.fetch(:till, Float::INFINITY)]
      elsif options[:month] && options[:year]
        [build_date(1), build_date(-1)]
      else
        [-Float::INFINITY, Float::INFINITY]
      end
    end

    def build_date(day)
      Date.new(options[:year], options[:month], day)
    end

    def filter_with_date_range?
      options[:from] || options[:till]
    end

    def currency
      options[:currency]
    end
  end
end
