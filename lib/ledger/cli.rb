module Ledger
  class Cli < Thor
    COMMANDS = {
      commands: 'List commands available in Ledger',
      create: 'Create a new ledger',
      edit: 'Open ledger in your editor',
      add: 'Add a transaction to the ledger',
      list: 'List all transactions on the ledger',
      report: 'Create a report about the transaction on the ledger according to any params provided',
      trips: 'Create a report about the trips specified on the ledger',
      version: 'Display installed Ledger version'
    }.freeze

    desc 'commands', COMMANDS[:commands]
    def commands
      say COMMANDS.keys.join("\n")
    end

    desc 'create', COMMANDS[:create]
    map 'c' => :create
    def create
      Ledger.new.create!
    end

    desc 'edit', COMMANDS[:edit]
    map 'e' => :edit
    def edit
      Ledger.new.edit!
    end

    desc 'add', COMMANDS[:add]
    map 'a' => :add
    method_option :transaction, type: :array, aliases: '-t'
    def add
      Ledger.new.add!(options[:transaction])
    end

    desc 'list', COMMANDS[:list]
    map 'l' => :list
    def list
      Printer.new.list
    end

    desc 'report', COMMANDS[:report]
    map 'r' => :report
    method_option :year, type: :numeric, default: -> { Date.today.cwyear }, aliases: '-y'
    method_option :monthly, type: :numeric, default: -> { Date.today.month }, aliases: '-m'
    method_option :from, type: :string, aliases: '-f'
    method_option :till, type: :string, aliases: '-t'
    method_option :account, type: :array, aliases: '-A'
    method_option :categories, type: :array, aliases: '-C'
    method_option :detailed, type: :boolean, default: false, aliases: '-d'
    def report
      options = self.options.each_with_object(Thor::CoreExt::HashWithIndifferentAccess.new) do |(k, v), h|
        next h[k] = Date.parse(v) if %i[from till].include?(k)
        next h[k] = v.call if v.is_a?(Proc)
        h[k] = v
      end.freeze

      Printer.new(options).report
    end

    desc 'trips', COMMANDS[:trips]
    map 't' => :trips
    method_option :detailed, type: :boolean, default: false, aliases: '-d'
    def trips
      Printer.new(options).trips
    end

    desc 'version', COMMANDS[:version]
    map '-v' => :version
    def version
      say "ledger #{::Ledger::VERSION}"
    end
  end
end
