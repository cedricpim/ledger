module Ledger
  module Action
    # Class responsible for opening the file defined in the options with the
    # editor defined on EDITOR
    class Edit < Base
      def call
        puts 'No editor defined ($EDITOR)' or return unless ENV['EDITOR']

        repository.open(resource) do |file|
          filepath = [file.path, options[:line]].compact.join(':')

          system([ENV['EDITOR'], filepath].compact.join(' '))
        end
      end
    end
  end
end
