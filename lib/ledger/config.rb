module Ledger
  class Config
    DEFAULT_CONFIG = File.join(XDG['CONFIG'].to_s, 'ledger', 'config').freeze
    FALLBACK_CONFIG = File.join(File.expand_path('..', __FILE__), 'config', 'default').freeze

    class << self
      def create
        FileUtils.mkdir_p(File.dirname(DEFAULT_CONFIG))
        FileUtils.cp(FALLBACK_CONFIG, DEFAULT_CONFIG)
      end

      def file
        return DEFAULT_CONFIG if File.exist?(DEFAULT_CONFIG)
        return FALLBACK_CONFIG if File.exist?(FALLBACK_CONFIG)
      end
    end

    attr_reader :config

    def initialize(file = self.class.file)
      puts 'Configuration file not found' or exit unless file

      @config = YAML.safe_load(ERB.new(File.read(file)).result, [Symbol])
    end

    def transaction_fields
      config.fetch(:fields).keys
    end
  end
end
