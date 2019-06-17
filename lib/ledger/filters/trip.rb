module Ledger
  module Filters
    # Class responsible for checking if a given entry should be filtered out or
    # not, based in the trip attribute.
    class Trip < Base
      def call(entry)
        !entry.trip.nil? && !entry.trip.empty? && (trip.nil? || entry.trip.match?(/#{trip}/i))
      end

      private

      def trip
        options[:trip]
      end
    end
  end
end
