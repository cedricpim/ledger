module Ledger
  # Module responsible for encapsulating other modules that contain shared
  # behaviour.
  module Modules
    # Module responsible for validating the record and raising an error if any
    # data is invalid/missing.
    module HasValidations
      def initialize(options = {})
        fail Repository::LineError, 'There was an invalid line while parsing the CSV' if options.keys.include?(nil)

        super
      end

      def validate!
        fail Repository::LineError, 'There was an invalid line while parsing the CSV' unless valid?
      end

      def valid?
        fail NotImplementedError, 'This method needs to be implemented in the class'
      end
    end
  end
end
