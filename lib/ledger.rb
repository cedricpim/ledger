require 'command_line_reporter'
require 'csv'
require 'erb'
require 'money'
require 'money/bank/google_currency'
require 'openssl'
require 'readline'
require 'tempfile'
require 'xdg'

I18n.enforce_available_locales = false
Money.default_bank = Money::Bank::GoogleCurrency.new

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

require_relative 'ledger/transaction'

# Namespace for the whole project
module Ledger; end
