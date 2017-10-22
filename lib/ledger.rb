# Class responsible for loading the ledger file into memory and storing all the
# transactions. It can also be queried to retrieve information regarding these
# transactions in several different ways.
class Ledger
  extend Forwardable

  ENCRYPTION_ALGORITHM = 'AES-256-CBC'.freeze

  FIELDS = %w[Account Date Category Description Amount Currency Travel Processed].freeze

  def_delegators :content, :accounts, :categories, :currencies, :descriptions, :travels, :trips, :report

  attr_accessor :transactions

  def initialize
    @transactions = []
  end

  def load!
    handle_encryption do
      CSV.foreach(file, headers: true) do |row|
        self.transactions << Transaction.new(*row.fields)
      end
    end
  end

  def add!
    transaction = TransactionBuilder.new(self).build!

    handle_encryption do
      File.open(file, 'a') { |file| file.write("#{transaction.to_ledger}\n") }
      File.write(file, File.read(file).gsub(/\n+/,"\n"))
    end
  end

  def create!
    return if File.exist?(filepath)

    CSV.open(filepath, 'wb') { |csv| csv << FIELDS }
  end

  def open!
    handle_encryption { system("#{ENV['EDITOR']} #{file.path}") }
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
    result = cipher.update(File.read(file))
    result << cipher.final
    File.open(file, 'w') { |file| file.write(result) }
  end

  def credentials
    [`#{ENV['LEDGER_PASSWORD']}`, `#{ENV['LEDGER_SALT']}`]
  end

  def content
    @content ||= Content.new(transactions)
  end

  def file
    @file ||= File.new(filepath)
  end

  def filepath
    @filepath ||= File.expand_path(ENV['LEDGER'])
  end
end
