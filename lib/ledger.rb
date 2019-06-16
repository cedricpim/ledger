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

%w[actions api filters modules printers reports].each do |folder|
  files = Dir[File.join(__dir__, 'ledger', folder, '**', '*.rb')]

  files.sort { |first, second| second.include?('base') ? 1 : first <=> second }.map { |file| require file }
end

Dir[File.join(__dir__, 'ledger', '*.rb')].map { |file| require file }

# Namespace for the whole project
module Ledger; end
