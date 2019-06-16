require 'xdg'

module Ledger
  # Class responsible for handling the configuration file and access its
  # fields.
  class Config
    DEFAULT_CONFIG = File.join(XDG['CONFIG'].to_s, 'ledger', 'config').freeze
    FALLBACK_CONFIG = File.join(File.expand_path('../../', __dir__), 'config', 'default').freeze

    attr_reader :config

    def initialize(file: default)
      puts 'Configuration file not found' or exit unless file

      @config = YAML.safe_load(ERB.new(File.read(file)).result, permitted_classes: [Symbol]).freeze
    end

    def default?
      File.exist?(DEFAULT_CONFIG)
    end

    def ledger
      @ledger ||= config.fetch(:ledger)
    end

    def networth
      @networth ||= config.dig(:networth, :file)
    end
    alias networth? networth

    def investments
      @investments ||= config.dig(:networth, :investments) || []
    end

    def exchange
      @exchange ||= config.fetch(:exchange)
    end

    def fields
      @fields ||= config.fetch(:fields)
    end

    def encryption
      @encryption ||= config.fetch(:encryption, {})
    end

    def credentials
      @credentials ||= [credential_value(:password), credential_value(:salt)]
    end

    def default_currency
      @default_currency ||= begin
        currency = config.dig(:fields, :currency)
        currency.fetch(:default, currency.fetch(:values, []).first)
      end
    end

    def default_value
      CONFIG.output(:default)
    end

    def exclusions(of:)
      Hash(config.dig(of, :exclude)).tap do |exclusions|
        exclusions[:categories] ||= []
        exclusions[:accounts] ||= []
      end
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

    def show_totals?
      config.dig(:format, :output, :show_totals)
    end

    private

    def default
      if File.exist?(DEFAULT_CONFIG)
        DEFAULT_CONFIG
      elsif File.exist?(FALLBACK_CONFIG)
        FALLBACK_CONFIG
      end
    end

    def credential_value(key)
      value = encryption.dig(:credentials, key)

      value || IO.popen(encryption.dig(:credentials, "#{key}eval".to_sym)).readlines.first.chomp
    end
  end
end
