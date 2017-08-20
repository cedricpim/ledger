# Class responsible for loading the ledger file into memory. It keeps two main
# entities: all the accounts and the transactions. It can also be queried to
# retrieve information regarding those entities.
class Ledger
  ENCRYPTION_ALGORITHM = 'AES-256-CBC'.freeze

  attr_accessor :accounts, :transactions

  def initialize
    @accounts = {}
    @transactions = []
  end

  def load!
    handle_encryption do
      transaction_section = false
      CSV.foreach(LEDGER) do |row|
        next if row.first == 'Code'
        transaction_section = true and next if row.first == 'Account Code'

        process(row, transaction_section)
      end
    end
  end

  def handle_encryption
    decrypt!
    yield
    encrypt!
  rescue OpenSSL::Cipher::CipherError
    yield
    encrypt!
  end

  def add!
    transaction = TransactionBuilder.new(self).build!

    handle_encryption do
      File.open(LEDGER, 'a') { |file| file.write("#{transaction.to_ledger}\n") }
      File.write(LEDGER, File.read(LEDGER).gsub(/\n+/,"\n")) # Clean empty lines
    end
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

  def decrypt!
    encryption { |cipher| cipher.decrypt }
  end

  def encrypt!
    encryption { |cipher| cipher.encrypt }
  end

  private

  def encryption
    return unless ENCRYPTION

    cipher = OpenSSL::Cipher.new(ENCRYPTION_ALGORITHM)
    yield cipher
    cipher.pkcs5_keyivgen(*credentials)
    result = cipher.update(File.read(LEDGER))
    result << cipher.final
    File.open(LEDGER, 'w') { |file| file.write(result) }
  end

  def credentials
    [DEFAULT_PASSWORD || ask_for_password, DEFAULT_SALT || Readline.readline('Salt: ', false)]
  end

  def ask_for_password
    print 'Password: '
    STDIN.noecho(&:gets).chomp
  end

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

