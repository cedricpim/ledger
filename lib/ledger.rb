# Class responsible for loading the ledger file into memory. It keeps two main
# entities: all the accounts and the transactions. It can also be queried to
# retrieve information regarding those entities.
class Ledger
  attr_accessor :accounts, :transactions

  def initialize
    @accounts = {}
    @transactions = []
  end

  def load!
    transaction_section = false
    CSV.foreach(LEDGER) do |row|
      next if row.first == 'Code'
      transaction_section = true and next if row.first == 'Account Code'

      process(row, transaction_section)
    end
    self
  end

  def add!
    transaction = TransactionBuilder.new(self).build!

    File.open(LEDGER, 'a') { |file| file.write("#{transaction.to_ledger}\n") }
    File.write(LEDGER, File.read(LEDGER).gsub(/\n+/,"\n")) # Clean empty lines
  end

  def existing_categories
    transactions.map(&:category).uniq.sort
  end

  def existing_descriptions
    transactions.map(&:description).uniq.compact.sort
  end

  def existing_currencies
    transactions.map(&:currency).uniq.sort
  end

  def existing_travels
    transactions.map(&:travel).uniq.compact.sort
  end

  def travels
    transactions.select { |t| t.travel && t.expense? }.group_by(&:travel).map { |t, trs| Trip.new(t, trs) }
  end

  private

  def process(row, transaction_section)
    if transaction_section
      account = accounts[row.shift]
      transaction = Transaction.new(account, *row)
      self.transactions << transaction
      account.amount += transaction.amount
    else
      self.accounts[row.first] = Account.new(*row)
    end
  end
end

