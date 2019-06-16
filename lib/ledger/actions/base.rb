module Ledger
  # Module responsible for encapsulating the actions that can be done to the
  # Ledger
  module Actions
    # Base class that contains behaviour shared by Action classes
    class Base
      attr_reader :options, :ledger

      def initialize(options, ledger: nil)
        @options = options
        @ledger = ledger
      end

      private

      def repository
        @repository ||= Repository.new
      end

      def resource
        options[:networth] ? :networth : :ledger
      end
    end
  end
end
