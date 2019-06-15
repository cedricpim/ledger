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
require_relative 'ledger/modules/has_validations'

require_relative 'ledger/cli'
require_relative 'ledger/encryption'
require_relative 'ledger/filter'
require_relative 'ledger/money_helper'
require_relative 'ledger/networth'
require_relative 'ledger/repository'
require_relative 'ledger/transaction'
require_relative 'ledger/version'

require_relative 'ledger/actions/base'
require_relative 'ledger/actions/book'
require_relative 'ledger/actions/book/transaction'
require_relative 'ledger/actions/configure'
require_relative 'ledger/actions/convert'
require_relative 'ledger/actions/create'
require_relative 'ledger/actions/edit'
require_relative 'ledger/actions/networth'
require_relative 'ledger/actions/show'

require_relative 'ledger/filters/base'
require_relative 'ledger/filters/category'
require_relative 'ledger/filters/include_account'
require_relative 'ledger/filters/include_category'
require_relative 'ledger/filters/period'
require_relative 'ledger/filters/present_category'
require_relative 'ledger/filters/trip'

require_relative 'ledger/reports/base'
require_relative 'ledger/reports/analysis'
require_relative 'ledger/reports/balance'
require_relative 'ledger/reports/comparison'
require_relative 'ledger/reports/networth'
require_relative 'ledger/reports/networth/store'
require_relative 'ledger/reports/report'
require_relative 'ledger/reports/total'
require_relative 'ledger/reports/total/period'
require_relative 'ledger/reports/trip'

require_relative 'ledger/printers/base'
require_relative 'ledger/printers/analysis'
require_relative 'ledger/printers/balance'
require_relative 'ledger/printers/comparison'
require_relative 'ledger/printers/networth'
require_relative 'ledger/printers/report'
require_relative 'ledger/printers/total'
require_relative 'ledger/printers/trip'

require 'ledger/api/just_etf'

# Namespace for the whole project
module Ledger; end
