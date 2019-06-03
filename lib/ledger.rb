require 'command_line_reporter'
require 'csv'
require 'faraday'
require 'erb'
require 'money'
require 'money/bank/open_exchange_rates_bank'
require 'nokogiri'
require 'openssl'
require 'readline'
require 'tempfile'
require 'xdg'

Money.locale_backend = nil

require_relative 'ledger/config'

CONFIG = Ledger::Config.new

# Set Exchange gem
if CONFIG.default?
  Money.default_bank = Money::Bank::OpenExchangeRatesBank.new.tap do |oxr|
    oxr.cache = CONFIG.exchange[:cache_file]
    oxr.app_id = CONFIG.exchange[:api_key]
    oxr.ttl_in_seconds = CONFIG.exchange[:ttl]
    oxr.update_rates
  end
end

require_relative 'ledger/modules/has_date'
require_relative 'ledger/modules/has_money'
require_relative 'ledger/modules/has_date_filtering'
require_relative 'ledger/modules/has_date_sorting'
require_relative 'ledger/modules/has_currency_conversion'

require_relative 'ledger/analysis'
require_relative 'ledger/cli'
require_relative 'ledger/comparison'
require_relative 'ledger/content'
require_relative 'ledger/encryption'
require_relative 'ledger/global_trip'
require_relative 'ledger/money_helper'
require_relative 'ledger/networth'
require_relative 'ledger/networth_calculation'
require_relative 'ledger/networth_content'
require_relative 'ledger/report_builder'
require_relative 'ledger/printer'
require_relative 'ledger/report'
require_relative 'ledger/repository'
require_relative 'ledger/total'
require_relative 'ledger/transaction'
require_relative 'ledger/transaction_builder'
require_relative 'ledger/trip'
require_relative 'ledger/version'

require_relative 'ledger/action/book'
require_relative 'ledger/action/convert'
require_relative 'ledger/action/edit'

require 'ledger/api/just_etf'

# Namespace for the whole project
module Ledger; end
