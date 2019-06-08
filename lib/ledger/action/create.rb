module Ledger
  module Action
    # Class responsible for creating the file defined in the options
    class Create < Base
      def call
        repository.encryption.each do |type, encryption|
          next if encryption.resource.size.positive?

          repository.add(nil, type: type, reset: true)
        end
      end
    end
  end
end
