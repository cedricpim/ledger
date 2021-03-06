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

  # Reverse is requires for when there are nested classes
  files.partition { |filepath| File.basename(filepath) == 'base.rb' }.map(&:reverse).flatten.each { |file| require file }
end

Dir[File.join(__dir__, 'ledger', '*.rb')].map { |file| require file }

# Set configuration
CONFIG = Ledger::Config.new

# Set Exchange gem
Money.rounding_mode = BigDecimal::ROUND_HALF_UP # TODO: remove after new version of Money gem
Money.locale_backend = nil
Money.default_currency = CONFIG.default_currency
Money.default_bank = Money::Bank::OpenExchangeRatesBank.new.tap do |oxr|
  oxr.cache = CONFIG.exchange[:cache_file]
  oxr.app_id = CONFIG.exchange[:api_key]
  oxr.ttl_in_seconds = CONFIG.exchange[:ttl]
  oxr.update_rates
end

# Namespace for the whole project
module Ledger; end
