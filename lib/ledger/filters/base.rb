module Ledger
  # Module responsible for encapsulating all the filtering done to transactions
  # or networth entries.
  module Filters
    # Base class that is inherited by all the other filters and sets up any
    # shared behaviour between filters.
    class Base
      attr_reader :options

      def initialize(options = {})
        @options = options
      end

      def inverted?
        options[:inverted]
      end
    end
  end
end
