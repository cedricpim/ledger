# Class responsible for loading the ledger file into memory and storing all the
# transactions, creating the ledger file or adding a new transaction.
class Ledger
  extend Forwardable

  def_delegators :content, :accounts, :categories, :currencies,
                 :descriptions, :travels, :trips, :report, :currency_per_account

  attr_accessor :transactions

  def initialize
    @transactions = []
  end

  def load!
    encryption.wrap do |file|
      CSV.foreach(file, headers: true) do |row|
        transactions << Transaction.new(*row.fields)
      end
    end
  end

  def add!
    transaction = TransactionBuilder.new(self).build!

    encryption.wrap do |file|
      File.open(file, 'a') { |f| f.write("#{transaction.to_ledger}\n") }
      File.write(file, File.read(file).gsub(/\n+/, "\n"))
    end
  end

  def create!
    filepath = File.expand_path(CONFIGS[:ledger])

    return if File.exist?(filepath)

    CSV.open(filepath, 'wb') { |csv| csv << CONFIGS[:fields].keys.map(&:capitalize) }

    encryption.encrypt!
  end

  def open!
    encryption.wrap { |file| system("#{ENV['EDITOR']} #{file.path}") }
  end

  private

  def encryption
    @encryption ||= Encryption.new
  end

  def content
    return @content if @content

    load!

    @content = Content.new(transactions)
  end
end
