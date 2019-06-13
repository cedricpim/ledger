module Ledger
  module Filters
    # Class responsible for checking if a given entry should be filtered out or
    # not, based in the account attribute and the accounts exclusion options
    class IncludeAccount < Base
      attr_reader :type

      def initialize(options, type)
        super(options)
        @type = type
      end

      def call(entry)
        !accounts.include?(entry.account.downcase)
      end

      private

      def accounts
        @accounts ||= CONFIG.exclusions(of: type).transform_values { |values| values.map(&:downcase) }[:accounts]
      end
    end
  end
end
