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

%w[actions api filters modules printers reports].each do |folder|
  files = Dir[File.join(__dir__, 'ledger', folder, '**', '*.rb')]

  files.sort { |fst, snd| snd.include?('base') ? 1 : fst <=> snd }.map { |file| require file }
end

Dir[File.join(__dir__, 'ledger', '*.rb')].map { |file| require file }

# Set configuration
CONFIG = Ledger::Config.new

# Set Exchange gem
Money.default_bank = Money::Bank::OpenExchangeRatesBank.new.tap do |oxr|
  oxr.cache = CONFIG.exchange[:cache_file]
  oxr.app_id = CONFIG.exchange[:api_key]
  oxr.ttl_in_seconds = CONFIG.exchange[:ttl]
  oxr.update_rates
end

# Namespace for the whole project
module Ledger; end
