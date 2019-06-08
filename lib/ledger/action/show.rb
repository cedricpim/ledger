module Ledger
  module Action
    # Class responsible for displaying all the transactions that match the
    # options provided
    class Show < Base
      def call
        repository.load(resource).each do |entity|
          system("echo \"#{entity.to_file}\" >> #{output.path}")
        end
      end

      private

      def output
        @output ||= File.new(options[:output], 'a')
      end
    end
  end
end
