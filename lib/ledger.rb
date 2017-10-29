require 'colorize'
require 'csv'
require 'erb'
require 'money'
require 'money/bank/google_currency'
require 'optparse'
require 'optparse/date'
require 'openssl'
require 'pry'
require 'readline'
require 'terminal-table'

require_relative 'lib/ui'

# Money configurations
I18n.enforce_available_locales = false
Money.default_bank = Money::Bank::GoogleCurrency.new

# Configurations
opts = UI.new.tap(&:run).options

puts 'Configuration file not found' or exit unless File.exist?(opts[:config])

CONFIGS = YAML.safe_load(ERB.new(File.read(opts[:config])).result, [Symbol]).freeze

Dir.glob(File.join(__dir__, 'lib', 'ledger', '*.rb')).each { |file| require file }

module Ledger
end
