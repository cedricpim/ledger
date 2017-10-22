# Class responsible for loading the ledger file into memory and storing all the
# transactions. It can also be queried to retrieve information regarding these
# transactions in several different ways.
class Ledger
  extend Forwardable

  ENCRYPTION_ALGORITHM = 'AES-256-CBC'.freeze

  def_delegators :content, :accounts, :categories, :currencies, :descriptions, :travels, :trips, :report

  attr_accessor :transactions

  def initialize
    @transactions = []
  end

  def load!
    handle_encryption do
      CSV.foreach(LEDGER, headers: true) do |row|
        self.transactions << Transaction.new(*row.fields)
      end
    end
  end

  def add!
    transaction = TransactionBuilder.new(self).build!

    handle_encryption do
      File.open(LEDGER, 'a') { |file| file.write("#{transaction.to_ledger}\n") }
      File.write(LEDGER, File.read(LEDGER).gsub(/\n+/,"\n"))
    end
  end

  def open!
    handle_encryption { system("#{ENV['EDITOR']} #{LEDGER.path}") }
  end

  def decrypt!
    encryption { |cipher| cipher.decrypt }
  end

  def encrypt!
    encryption { |cipher| cipher.encrypt }
  end

  private

  def handle_encryption
    decrypt!
    yield
    encrypt!
  rescue OpenSSL::Cipher::CipherError
    yield
    encrypt!
  end

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
    [DEFAULT_PASSWORD || ask_for(:password), DEFAULT_SALT || ask_for(:salt)]
  end

  def ask_for(title)
    print "#{title.to_s.capitalize}: "
    STDIN.noecho(&:gets).chomp
  end

  def content
    @content ||= Content.new(transactions)
  end
end
