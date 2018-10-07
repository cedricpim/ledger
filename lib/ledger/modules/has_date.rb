module Ledger
  # Module responsible for encapsulating other modules that contain shared
  # behaviour.
  module Modules
    # Module responsible for holding behaviour regarding classes that have a
    # date as an attribute.
    module HasDate
      def parsed_date
        @parsed_date ||= date.is_a?(String) ? Date.parse(date) : date
      end
    end
  end
end
