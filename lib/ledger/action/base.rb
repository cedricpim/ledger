module Ledger
  # Module responsible for encapsulating the actions that can be done to the
  # Ledger
  module Action
    # Base class that contains behaviour shared by Action classes
    class Base
      attr_reader :options, :repository

      def initialize(options = {})
        @options = options
        @repository = Repository.new
      end

      private

      def resource
        options[:networth] ? :networth : :ledger
      end
    end
  end
end
