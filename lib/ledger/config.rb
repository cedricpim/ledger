module Ledger
  # Class responsible for handling the configuration file and access its
  # fields.
  class Config
    DEFAULT_CONFIG = File.join(XDG['CONFIG'].to_s, 'ledger', 'config').freeze
    FALLBACK_CONFIG = File.join(File.expand_path('../../../', __FILE__), 'config', 'default').freeze

    class << self
      def configure
        return if File.exist?(DEFAULT_CONFIG)

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

    def ledger
      config.fetch(:ledger)
    end

    def exchange
      config.fetch(:exchange)
    end

    def fields
      config.fetch(:fields)
    end

    def transaction_fields
      fields.keys
    end

    def encryption
      config.fetch(:encryption, {})
    end

    def credentials
      [credential_value(:password), credential_value(:salt)]
    end

    def credential_value(key)
      value = encryption.dig(:credentials, key)

      value || `encryption.dig(:credentials, "#{key}eval".to_sym)`.chomp
    end

    def default_currency
      currency = config.dig(:fields, :currency)
      currency.fetch(:default, currency.fetch(:values, []).first)
    end

    def default_excluded_categories
      fields = config.dig(:format, :fields)
      fields.fetch(:excluded_categories, []).map(&:downcase)
    end

    def color(*fields)
      output(:color, *fields)
    end

    def output(*fields)
      config.dig(:format, :output, *fields)
    end

    def money_format(type:)
      config.dig(:format, :fields, :money, type)
    end
  end
end
