module Ledger
  # Module responsible for encapsulating other modules that contain shared
  # behaviour.
  module Modules
    # Module responsible for holding behaviour regarding classes that have
    # are sorted based on parsed_date.
    module HasDateSorting
      attr_reader :list, :options

      def initialize(list, options)
        @list = list.sort_by(&:parsed_date)
        @options = options
      end
    end
  end
end
