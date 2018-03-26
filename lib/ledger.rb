require 'command_line_reporter'
require 'csv'
require 'erb'
require 'money'
require 'money/bank/open_exchange_rates_bank'
require 'openssl'
require 'readline'
require 'tempfile'
require 'xdg'

# Fixed on https://github.com/spk/money-open-exchange-rates/pull/46
class Money
  module Bank
    class OpenExchangeRatesBank < Money::Bank::VariableExchange
      def calc_pair_rate_using_base(from_currency, to_currency, opts)
        from_base_rate = get_rate_or_calc_inverse(source, from_currency, opts)
        to_base_rate   = get_rate_or_calc_inverse(source, to_currency, opts)
        if to_base_rate && from_base_rate
          rate = BigDecimal(to_base_rate.to_s) / from_base_rate
          add_rate(from_currency, to_currency, rate)
          return rate
        end
        nil
      end
    end
  end
end

I18n.enforce_available_locales = false

require_relative 'ledger/config'
require_relative 'ledger/cli'
require_relative 'ledger/content'
require_relative 'ledger/encryption'
require_relative 'ledger/money_helper'
require_relative 'ledger/report_builder'
require_relative 'ledger/printer'
require_relative 'ledger/report'
require_relative 'ledger/repository'
require_relative 'ledger/transaction_builder'
require_relative 'ledger/trip'
require_relative 'ledger/version'

# Configurations
CONFIG = Ledger::Config.new

# Set Exchange gem
Money.default_bank = Money::Bank::OpenExchangeRatesBank.new.tap do |oxr|
  oxr.cache = CONFIG.exchange[:cache_file]
  oxr.app_id = CONFIG.exchange[:api_key]
  oxr.ttl_in_seconds = CONFIG.exchange[:ttl]
  oxr.update_rates
end

require_relative 'ledger/transaction'

# Namespace for the whole project
module Ledger; end
