module Ledger
  module Filters
    # Class responsible for checking if a given entry should be filtered out or
    # not, based in the account attribute and the accounts exclusion options
    class ExcludeAccount < Base
      attr_reader :type

      def initialize(options, type)
        super(options)
        @type = type
      end

      def call(entry)
        !exclusions.include?(entry.account.downcase)
      end

      private

      def exclusions
        @exclusions ||= CONFIG.exclusions(of: type).transform_values { |values| values.map(&:downcase) }[:accounts]
      end
    end
  end
end
