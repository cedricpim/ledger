require 'command_line_reporter'
require 'csv'
require 'erb'
require 'money'
require 'money/bank/google_currency'
require 'openssl'
require 'readline'
require 'tempfile'
require 'xdg'

# Configurations
require_relative 'ledger/config'
CONFIG = Ledger::Config.new

Dir.glob(File.join(__dir__, 'ledger', '*.rb')).each { |file| require file }

I18n.enforce_available_locales = false
Money.default_bank = Money::Bank::GoogleCurrency.new

# Namespace for the whole project
module Ledger; end
