module Ledger
  # Class responsible for handling all the commands that Ledger can execute
  # from command-line.
  class Cli < Thor # rubocop:disable Metrics/ClassLength
    COMMANDS = {
      analysis: 'List all transactions on the ledger for the specified category',
      balance: 'List the current balance of each account',
      book: 'Add a transaction to the ledger',
      commands: 'List commands available in Ledger',
      compare: 'Compare multiple periods',
      configure: 'Copy provided configuration file to the default location',
      convert: 'Convert other currencies to main currency of the account',
      create: 'Create a new ledger/networth file',
      edit: 'Open ledger/networth file in your editor',
      networth: 'Calculate current networth',
      report: 'Create a report about the transactions on the ledger according to any params provided',
      show: 'Display all transactions',
      trip: 'Create a report about the trips present on the ledger',
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
    map 'C' => :configure
    def configure
      Config.configure
    end

    desc 'convert', COMMANDS[:convert]
    def convert
      Action::Convert.new.call
    end

    desc 'create', COMMANDS[:create]
    method_option :networth, type: :boolean, default: false, aliases: '-n'
    def create
      Repository.new(parsed_options).create!
    end

    desc 'edit', COMMANDS[:edit]
    map 'e' => :edit
    method_option :line, type: :numeric, aliases: '-l'
    method_option :networth, type: :boolean, default: false, aliases: '-n'
    def edit
      Repository.new(parsed_options).edit!
    end

    desc 'book', COMMANDS[:book]
    method_option :transaction, type: :array, aliases: '-t'
    def book
      Action::Book.new(parsed_options).call
    end

    desc 'balance', COMMANDS[:balance]
    map 'b' => :balance
    method_option :all, type: :boolean, default: false, aliases: '-a'
    method_option :date, type: :string, aliases: '-d'
    def balance
      Printer.new(parsed_options).balance
    end

    desc 'analysis [CATEGORY]', COMMANDS[:analysis]
    map 'a' => :analysis
    method_option :year, type: :numeric, default: -> { Date.today.year }, aliases: '-y'
    method_option :month, type: :numeric, default: -> { Date.today.month }, aliases: '-m'
    method_option :from, type: :string, aliases: '-f'
    method_option :till, type: :string, aliases: '-t'
    method_option :global, type: :boolean, default: true, aliases: '-g'
    method_option :currency, type: :string, default: -> { CONFIG.default_currency }, aliases: '-c'
    def analysis(category)
      Printer.new(parsed_options).analysis(category)
    end

    desc 'report', COMMANDS[:report]
    map 'r' => :report
    method_option :year, type: :numeric, default: -> { Date.today.year }, aliases: '-y'
    method_option :month, type: :numeric, default: -> { Date.today.month }, aliases: '-m'
    method_option :from, type: :string, aliases: '-f'
    method_option :till, type: :string, aliases: '-t'
    method_option :categories, type: :array, aliases: '-C'
    method_option :global, type: :boolean, default: true, aliases: '-g'
    method_option :currency, type: :string, default: -> { CONFIG.default_currency }, aliases: '-c'
    def report
      Printer.new(parsed_options).report
    end

    desc 'show', COMMANDS[:show]
    map 's' => :show
    method_option :year, type: :numeric, aliases: '-y'
    method_option :month, type: :numeric, aliases: '-m'
    method_option :from, type: :string, aliases: '-f'
    method_option :till, type: :string, aliases: '-t'
    method_option :currency, default: -> { CONFIG.default_currency }, type: :string, aliases: '-c'
    method_option :output, type: :string, default: -> { '/dev/stdout' }, aliases: '-o'
    method_option :networth, type: :boolean, default: false, aliases: '-n'
    def show
      Repository.new(parsed_options).show
    end

    desc 'trip', COMMANDS[:trip]
    map 't' => :trip
    method_option :trip, type: :string, aliases: '-t'
    method_option :global, type: :boolean, default: true, aliases: '-g'
    method_option :currency, type: :string, default: -> { CONFIG.default_currency }, aliases: '-c'
    def trip
      Printer.new(parsed_options).trip
    end

    desc 'networth', COMMANDS[:networth]
    map 'n' => :networth
    method_option :store, type: :boolean, default: false, aliases: '-s'
    method_option :currency, type: :string, default: -> { CONFIG.default_currency }, aliases: '-c'
    def networth
      if parsed_options[:store]
        Repository.new(parsed_options).networth!
      else
        Printer.new(parsed_options).networth
      end
    end

    desc 'version', COMMANDS[:version]
    map '-v' => :version
    def version
      say "ledger #{::Ledger::VERSION}"
    end

    private

    def parsed_options
      options.each_with_object(Thor::CoreExt::HashWithIndifferentAccess.new) do |(k, v), h|
        next if k == 'networth' && !CONFIG.networth?
        next h[k] = Date.parse(v) if %w[from till date].include?(k)
        next h[k] = v.call if v.is_a?(Proc)

        h[k] = v
      end.freeze
    end
  end
end
