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
        @transactions ||= Filter.new(repository.load(:ledger), filters: filters, currency: currency).call
      end

      def filters
        fail NotImplementedError, 'This method must be implemented in the child class'
      end
    end
  end
end
