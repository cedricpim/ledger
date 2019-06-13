module Ledger
  module Filters
    # Class responsible for checking if a given entry should be filtered out or
    # not, based in the category attribute and the categories exclusion options
    class IncludeCategory < Base
      attr_reader :type

      def initialize(options, type)
        super(options)
        @type = type
      end

      def call(entry)
        !categories.include?(entry.category.downcase)
      end

      private

      def categories
        @categories ||= CONFIG.exclusions(of: type).transform_values { |values| values.map(&:downcase) }[:categories]
      end
    end
  end
end
