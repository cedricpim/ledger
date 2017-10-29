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

require_relative 'ledger/ui'

# Money configurations
I18n.enforce_available_locales = false
Money.default_bank = Money::Bank::GoogleCurrency.new

# Configurations
opts = UI.new.tap(&:run).options

puts 'Configuration file not found' or exit unless File.exist?(opts[:config])

CONFIGS = YAML.safe_load(ERB.new(File.read(opts[:config])).result, [Symbol]).freeze

Dir.glob(File.join(__dir__, 'ledger', '*.rb')).each { |file| require file }

# Namespace for the whole project
module Ledger
end

Ledger::Ledger.new.create! or exit if ARGV[0] == 'create'

case
when opts[:add]        then Ledger::Ledger.new.add!(opts[:transaction])
when opts[:open]       then Ledger::Ledger.new.open!
when opts[:list]       then Printer.new.list
when opts[:trips]      then Printer.new(opts[:trip]).trips
when opts[:report]     then Printer.new(opts[:report]).report
end
