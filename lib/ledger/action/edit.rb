module Ledger
  # Module responsible for encapsulating the actions that can be done to the
  # Ledger
  module Action
    # Class responsible for opening the file defined in the options with the
    # editor defined on EDITOR
    class Edit
      attr_reader :options

      def initialize(options = {})
        @options = options
      end

      def call
        puts 'No editor defined ($EDITOR)' or return unless ENV['EDITOR']

        repository.open(resource) do |file|
          filepath = [file.path, options[:line]].compact.join(':')
          system("#{ENV['EDITOR']} #{filepath}")
        end
      end

      private

      def resource
        options[:networth] ? :networth : :ledger
      end

      def repository
        @repository ||= Repository.new
      end
    end
  end
end
