module Ledger
  module Filters
    # Class responsible for checking if a given entry should be filtered out or
    # not, based in the parsed_date attribute.
    class Period < Base
      def call(entry)
        entry.parsed_date.between?(*period)
      end

      private

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
    end
  end
end
