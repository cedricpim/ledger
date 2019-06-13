module Ledger
  module Filters
    # Class responsible for checking if a given entry should be filtered out or
    # not, based in the category attribute and the categories exclusion options
    class PresentCategory < Base
      def call(entry)
        !categories.include?(entry.category.downcase)
      end

      private

      def categories
        @categories ||= Array(options[:categories]).map(&:downcase)
      end
    end
  end
end
