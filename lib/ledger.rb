require 'colorize'
require 'csv'
require 'erb'
require 'money'
require 'money/bank/google_currency'
require 'openssl'
require 'pry'
require 'readline'
require 'xdg'

require_relative 'ledger/config'

# Money configurations (TODO: can I get rid of this?)
I18n.enforce_available_locales = false
Money.default_bank = Money::Bank::GoogleCurrency.new

# Configurations
CONFIG = Ledger::Config.new

Dir.glob(File.join(__dir__, 'ledger', '*.rb')).each { |file| require file }

# Namespace for the whole project
module Ledger; end
