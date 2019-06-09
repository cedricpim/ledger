module Ledger
  module Filters
    # Class responsible for checking if a given entry should be filtered out or
    # not, based in the category attribute and the category provided
    class Category < Base
      attr_reader :category

      def initialize(options, category)
        super(options)
        @category = category
      end

      def call(entry)
        entry.category.casecmp(category).zero?
      end
    end
  end
end
