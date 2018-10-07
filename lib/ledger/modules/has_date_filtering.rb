module Ledger
  # Module responsible for encapsulating other modules that contain shared
  # behaviour.
  module Modules
    # Module responsible for holding behaviour regarding classes that have
    # date based filtering.
    module HasDateFiltering
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
