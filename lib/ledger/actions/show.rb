module Ledger
  module Actions
    # Class responsible for displaying all the transactions that match the
    # options provided
    class Show < Base
      def call
        entries.each { |entry| system("echo \"#{entry.to_file}\" >> #{output.path}") }
      end

      private

      def filters
        [
          Filters::Period.new(options),
          Filters::PresentCategory.new(options)
        ]
      end

      def entries
        Filter.new(repository.load(resource), filters: filters, currency: currency).call
      end

      def currency
        return unless options[:currency] && !options[:currency].empty?

        options[:currency]
      end

      def output
        @output ||= File.new(options[:output], 'a')
      end
    end
  end
end
