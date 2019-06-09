module Ledger
  module Filters
    # Class responsible for checking if a given entry should be filtered out or
    # not, based in the category attribute and the categories exclusion options
    class ExcludeCategory < Base
      attr_reader :type

      def initialize(options, type)
        super(options)
        @type = type
      end

      def call(entry)
        category = entry.category.downcase

        !exclusions.include?(category) && (categories.nil? || !categories.include?(category))
      end

      private

      def categories
        Array(options[:categories]).map(&:downcase)
      end

      def exclusions
        @exclusions ||= CONFIG.exclusions(of: type).transform_values { |values| values.map(&:downcase) }[:categories]
      end
    end
  end
end
