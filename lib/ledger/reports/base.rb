module Ledger
  # Module responsible for encapsulating all the classes related to reports.
  module Reports
    # Class responsible for holding the common behaviour between generating
    # reports.
    class Base
      attr_reader :options

      def initialize(options = {})
        @options = options
      end

      private

      def repository
        @repository ||= Repository.new
      end

      def currency
        options[:currency]
      end

      def transactions
        @transactions ||= Filter.new(ledger, filters: filters, currency: currency).call
      end

      def ledger
        @ledger ||= repository.load(:ledger).sort_by(&:parsed_date)
      end

      def filters
        fail NotImplementedError, 'This method must be implemented in the child class'
      end

      def currency_for
        @currency_for ||= ledger.group_by(&:account).transform_values { |ats| ats.first.currency }
      end
    end
  end
end
