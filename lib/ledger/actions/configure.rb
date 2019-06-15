module Ledger
  module Actions
    # Class responsible for creating the file defined in the options
    class Configure < Base
      def call
        return if File.exist?(Ledger::Config::DEFAULT_CONFIG)

        FileUtils.mkdir_p(File.dirname(Ledger::Config::DEFAULT_CONFIG))
        FileUtils.cp(Ledger::Config::FALLBACK_CONFIG, Ledger::Config::DEFAULT_CONFIG)
      end
    end
  end
end
