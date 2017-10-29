# Class responsible for reading the command, parsing it and setting the options
# requested accordingly.
class UI
  attr_reader :options

  def initialize
    @options = {config: File.expand_path('~/.config/ledger/config'), transaction: []}
  end

  def run
    OptionParser.new do |opts|
      opts.banner = 'Usage: money [options]'

      configuration_file(opts)
      transaction_operations(opts)
      listings(opts)
      reports(opts)
      trips(opts)
      help(opts)
    end.parse!
  end

  private

  def configuration_file(opts)
    opts.on('-C [STRING]', '--config', 'Configuration file') { |config| options[:config] = config }
  end

  def transaction_operations(opts)
    opts.on('-a', '--add', 'Add Transaction') { options[:add] = true }

    opts.on('-A x,y,z', Array, 'Add Transaction with parameters provided') do |transaction|
      options[:add] = true
      options[:transaction] = transaction
    end

    opts.on('-o', '--open', 'Open CSV file') { |open| options[:open] = open }
  end

  def listings(opts)
    opts.on('-l', '--list', 'List Transactions') { options[:list] = true }
  end

  def reports(opts)
    opts.on('-r', '--report', 'Generate a report') do
      options[:report] = {summary: true}

      group_reports(opts)
      date_reports(opts)
      inclusions_and_exclusions(opts)
      detailed_reports(opts)
    end
  end

  def inclusions_and_exclusions(opts)
    opts.on('-A x,y,z', Array, 'Only include accounts provided') do |accounts|
      options[:report][:accounts] = accounts
    end

    opts.on('-e x,y,z', Array, 'Excluding categories provided') do |categories|
      options[:report][:exclude] = categories
    end
  end

  def group_reports(opts)
    opts.on('-a [INTEGER]', '--annual', Integer, 'From year provided') do |annual|
      options[:report][:annual] = annual || Date.today.cwyear
    end

    opts.on('-m [INTEGER]', '--monthly', Integer, 'From month provided') do |month|
      options[:report][:monthly] = month || Date.today.month
    end
  end

  def date_reports(opts)
    opts.on('-f [DATE]', Date, 'Since date provided') do |from|
      options[:report][:from] = from
    end

    opts.on('-t [DATE]', Date, 'Until date provided') do |till|
      options[:report][:till] = till
    end
  end

  def detailed_reports(opts)
    opts.on('-d', 'Detailing each transaction') do |detailed|
      options[:report][:detailed] = detailed
      options[:report][:summary] = false
    end
  end

  def trips(opts)
    opts.on('-t', '--trips', 'List trip expenses') do
      options[:trips] = {summary: true}

      opts.on('-d', 'Detailing each transaction') do |detailed|
        options[:trips][:detailed] = detailed
        options[:trips][:summary] = false
      end
    end
  end

  def help(opts)
    opts.on('-h', '--help', 'Display this screen') do
      puts opts
      exit
    end
  end
end
