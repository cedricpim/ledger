# Class responsible for loading the ledger file into memory and storing all the
# transactions, creating the ledger file or adding a new transaction.
class Ledger
  extend Forwardable

  def_delegators :content, :list, :accounts, :categories, :currencies,
                 :descriptions, :travels, :trips, :report, :accounts_currency

  attr_reader :transactions

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

  def add!(params)
    transaction = TransactionBuilder.new(self).build!(params)

    encryption.wrap do |file|
      File.open(file, 'a') { |f| f.write("#{transaction.to_ledger}\n") }
      File.write(file, File.read(file).gsub(/\n+/, "\n"))
    end
  end

  def create!
    filepath = File.expand_path(CONFIGS.fetch(:ledger))

    return if File.exist?(filepath)

    CSV.open(filepath, 'wb') { |csv| csv << CONFIGS.fetch(:fields).keys.map(&:capitalize) }

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
