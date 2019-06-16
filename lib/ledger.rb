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

%w[actions filters reports printers].each do |folder|
  require_relative "ledger/#{folder}/base"

  Dir[File.join(__dir__, 'ledger', folder, '**', '*.rb')].sort.map { |file| require file }
end

require 'ledger/api/just_etf'

# Namespace for the whole project
module Ledger; end
