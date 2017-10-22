# Class responsible for reading the command, parsing it and setting the options
# requested accordingly.
class UI
  attr_reader :options

  def initialize
    @options = {}
  end

  def run
    OptionParser.new do |opts|
      opts.banner = "Usage: money [options]"

      opts.on("-a", "--add", "Add Transaction") do |add|
        options[:add] = add
      end

      opts.on("-b", "--balance", "List current balance of accounts") do |balance|
        options[:balance] = balance
      end

      opts.on("-c", "--categories", "List Categories") do |categories|
        options[:categories] = categories
      end

      if ENCRYPTION
        opts.on("-d", "--decrypt", "Decrypt ledger") do |decrypt|
          options[:decrypt] = decrypt
        end

        opts.on("-e", "--encrypt", "Encrypt ledger") do |encrypt|
          options[:encrypt] = encrypt
        end
      end

      opts.on("-o", "--open", "Open CSV file") do |open|
        options[:open] = open
      end

      opts.on("-l", "--list", "List Transactions") do |transactions|
        options[:transactions] = transactions
      end

      opts.on("-r", "--report", "Generate a report") do
        options[:report] = {summary: true}

        opts.on("-a [INTEGER]", "--annual", Integer, "From year provided") do |annual|
          options[:report][:annual] = annual || Date.today.cwyear
        end

        opts.on("-m [INTEGER]", "--monthly", Integer, "From month provided") do |month|
          options[:report][:monthly] = month || Date.today.month
        end

        opts.on("-f [DATE]", Date, "Since date provided") do |from|
          options[:report][:from] = from
        end

        opts.on("-t [DATE]", Date, "Until date provided") do |till|
          options[:report][:till] = till
        end

        opts.on("-e x,y,z", Array, "Excluding categories provided") do |categories|
          options[:report][:exclude] = categories
        end

        opts.on("-d", "Detailing each transaction") do |detailed|
          options[:report][:detailed] = detailed
          options[:report][:summary] = false
        end
      end

      opts.on("-t", "--trips", "List trip expenses") do |trips|
        options[:trips] = {summary: true}

        opts.on("-d", "Detailing each transaction") do |detailed|
          options[:trips][:detailed] = detailed
          options[:trips][:summary] = false
        end
      end

      opts.on('-h', '--help', 'Display this screen' ) do
        puts opts
        exit
      end
    end.parse!
  end
end
