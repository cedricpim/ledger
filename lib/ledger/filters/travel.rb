module Ledger
  module Filters
    # Class responsible for checking if a given entry should be filtered out or
    # not, based in the travel attribute.
    class Travel < Base
      def call(entry)
        !entry.travel.nil? && !entry.travel.empty? && (trip.nil? || entry.travel.match?(/#{trip}/i))
      end

      private

      def trip
        options[:trip]
      end
    end
  end
end
