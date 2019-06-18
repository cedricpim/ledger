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

    desc 'configure', COMMANDS[:configure]
    map 'C' => :configure
    def configure
      Actions::Configure.new(parsed_options).call
    end

    desc 'convert', COMMANDS[:convert]
    def convert
      Actions::Convert.new(parsed_options).call
    end

    desc 'create', COMMANDS[:create]
    def create
      Actions::Create.new(parsed_options).call
    end

    desc 'edit', COMMANDS[:edit]
    map 'e' => :edit
    method_option :line, type: :numeric, aliases: '-l'
    method_option :networth, type: :boolean, default: false, aliases: '-n'
    def edit
      Actions::Edit.new(parsed_options).call
    end

    desc 'book', COMMANDS[:book]
    method_option :transaction, type: :array, aliases: '-t'
    def book
      Actions::Book.new(parsed_options).call
    end

    desc 'show', COMMANDS[:show]
    map 's' => :show
    method_option :year, type: :numeric, aliases: '-y'
    method_option :month, type: :numeric, aliases: '-m'
    method_option :from, type: :string, aliases: '-f'
    method_option :till, type: :string, aliases: '-t'
    method_option :categories, type: :array, aliases: '-C'
    method_option :currency, default: -> { CONFIG.default_currency }, type: :string, aliases: '-c'
    method_option :output, type: :string, default: -> { '/dev/stdout' }, aliases: '-o'
    method_option :networth, type: :boolean, default: false, aliases: '-n'
    def show
      Actions::Show.new(parsed_options).call
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
      report = Reports::Analysis.new(parsed_options, category: category)
      total = total(report.ledger, with_period: true)

      data = data(report, global: parsed_options[:global])
      Printers::Analysis.new(total: total).call(data)
    end

    desc 'balance', COMMANDS[:balance]
    map 'b' => :balance
    method_option :all, type: :boolean, default: false, aliases: '-a'
    method_option :date, type: :string, aliases: '-d'
    def balance
      report = Reports::Balance.new(parsed_options)
      total = total(report.ledger, with_period: false)

      Printers::Balance.new(total: total).call(report.data)
    end

    desc 'compare', COMMANDS[:compare]
    map 'c' => :compare
    method_option :months, type: :numeric, default: 1, aliases: '-m'
    method_option :currency, type: :string, default: -> { CONFIG.default_currency }, aliases: '-c'
    def compare
      report = Reports::Comparison.new(parsed_options)

      Printers::Comparison.new.call(report.periods, report.data, report.totals)
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
      report = Reports::Report.new(parsed_options)
      total = total(report.ledger, with_period: true)

      data = data(report, global: parsed_options[:global])
      Printers::Report.new(total: total).call(data)
    end

    desc 'trip', COMMANDS[:trip]
    map 't' => :trip
    method_option :trip, type: :string, aliases: '-t'
    method_option :global, type: :boolean, default: true, aliases: '-g'
    method_option :currency, type: :string, default: -> { CONFIG.default_currency }, aliases: '-c'
    def trip
      report = Reports::Trip.new(parsed_options)

      data = data(report, global: parsed_options[:global])
      Printers::Trip.new(global: parsed_options[:global]).call(data)
    end

    desc 'networth', COMMANDS[:networth]
    map 'n' => :networth
    method_option :store, type: :boolean, default: false, aliases: '-s'
    method_option :currency, type: :string, default: -> { CONFIG.default_currency }, aliases: '-c'
    def networth
      report = Reports::Networth.new(parsed_options)

      if parsed_options[:store]
        Actions::Networth.new(parsed_options, ledger: report.ledger).call(report.store)
      else
        Printers::Networth.new.call(report.data)
      end
    end

    desc 'version', COMMANDS[:version]
    map '-v' => :version
    def version
      say "ledger #{::Ledger::VERSION}"
    end

    private

    def data(report, global:)
      global ? report.global : report.data
    end

    def total(ledger, with_period:)
      report = Reports::Total.new(parsed_options, ledger: ledger)

      proc { Printers::Total.new(with_period: with_period).call(report.period, report.total) }
    end

    def parsed_options
      options.each_with_object(Thor::CoreExt::HashWithIndifferentAccess.new) do |(k, v), h|
        next if skip?(k.to_sym, options)
        next h[k] = Date.parse(v) if %w[from till date].include?(k)
        next h[k] = v.call if v.is_a?(Proc)

        h[k] = v
      end.freeze
    end

    def skip?(key, options)
      (key == :networth && !CONFIG.networth?) || (key == :global && options[:trip])
    end
  end
end
