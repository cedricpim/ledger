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

      opts.on("-o", "--open", "Open CSV file") do
        exec("$EDITOR #{FILE.path}")
      end

      opts.on("-t", "--transactions", "List Transactions") do |transactions|
        options[:transactions] = transactions
      end

      opts.on("-r", "--report", "Generate a report") do
        options[:report] = {summary: true}

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

      opts.on("-T", "--travels", "List travel expenses") do |travels|
        options[:travels] = {summary: true}

        opts.on("-d", "Detailing each transaction") do |detailed|
          options[:travels][:detailed] = detailed
          options[:travels][:summary] = false
        end
      end

      opts.on('-h', '--help', 'Display this screen' ) do
        puts opts
        exit
      end
    end.parse!
  end
end
