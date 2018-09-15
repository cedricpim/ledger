module Ledger
  # Class responsible for handling all the commands that Ledger can execute
  # from command-line.
  class Cli < Thor
    COMMANDS = {
      analyse: 'List all transactions on the ledger for the specified category',
      balance: 'List the current balance of each account',
      book: 'Add a transaction to the ledger',
      commands: 'List commands available in Ledger',
      compare: 'Compare multiple periods',
      configure: 'Copy provided configuration file to the default location',
      create: 'Create a new ledger and copy default configuration file',
      edit: 'Open ledger in your editor',
      report: 'Create a report about the transaction on the ledger according to any params provided',
      trips: 'Create a report about the trips specified on the ledger',
      version: 'Display installed Ledger version'
    }.freeze

    desc 'commands', COMMANDS[:commands]
    def commands
      say COMMANDS.keys.join("\n")
    end

    desc 'compare', COMMANDS[:compare]
    map 'c' => :compare
    method_option :months, type: :numeric, default: 1, aliases: '-m'
    method_option :currency, type: :string, default: -> { CONFIG.default_currency }, aliases: '-c'
    def compare
      Printer.new(parsed_options).compare
    end

    desc 'configure', COMMANDS[:configure]
    map '-c' => :configure
    def configure
      Config.configure
    end

    desc 'create', COMMANDS[:create]
    def create
      Repository.new.create!
    end

    desc 'edit', COMMANDS[:edit]
    map 'e' => :edit
    method_option :line, type: :numeric, aliases: '-l'
    def edit
      Repository.new(parsed_options).edit!
    end

    desc 'book', COMMANDS[:book]
    map 'b' => :book
    method_option :transaction, type: :array, aliases: '-t'
    def book
      Repository.new(parsed_options).book!
    end

    desc 'balance', COMMANDS[:balance]
    map 'b' => :balance
    method_option :all, type: :boolean, default: false, aliases: '-a'
    method_option :date, type: :string, aliases: '-d'
    def balance
      Printer.new(parsed_options).balance
    end

    desc 'analyse [CATEGORY]', COMMANDS[:analyse]
    map 'a' => :analyse
    method_option :year, type: :numeric, default: -> { Date.today.cwyear }, aliases: '-y'
    method_option :month, type: :numeric, default: -> { Date.today.month }, aliases: '-m'
    method_option :from, type: :string, aliases: '-f'
    method_option :till, type: :string, aliases: '-t'
    method_option :global, type: :boolean, default: true, aliases: '-g'
    method_option :currency, type: :string, default: -> { CONFIG.default_currency }, aliases: '-c'
    def analyse(category)
      Printer.new(parsed_options).analyse(category)
    end

    desc 'report', COMMANDS[:report]
    map 'r' => :report
    method_option :year, type: :numeric, default: -> { Date.today.cwyear }, aliases: '-y'
    method_option :month, type: :numeric, default: -> { Date.today.month }, aliases: '-m'
    method_option :from, type: :string, aliases: '-f'
    method_option :till, type: :string, aliases: '-t'
    method_option :categories, type: :array, aliases: '-C'
    method_option :global, type: :boolean, default: true, aliases: '-g'
    method_option :currency, type: :string, default: -> { CONFIG.default_currency }, aliases: '-c'
    def report
      Printer.new(parsed_options).report
    end

    desc 'trips', COMMANDS[:trips]
    map 't' => :trips
    method_option :currency, type: :string, default: -> { CONFIG.default_currency }, aliases: '-c'
    method_option :global, type: :boolean, default: true, aliases: '-g'
    method_option :trip, type: :string, aliases: '-t'
    def trips
      Printer.new(parsed_options).trips
    end

    desc 'version', COMMANDS[:version]
    map '-v' => :version
    def version
      say "ledger #{::Ledger::VERSION}"
    end

    private

    def parsed_options
      options.each_with_object(Thor::CoreExt::HashWithIndifferentAccess.new) do |(k, v), h|
        next h[k] = Date.parse(v) if %w[from till date].include?(k)
        next h[k] = v.call if v.is_a?(Proc)
        h[k] = v
      end.freeze
    end
  end
end
