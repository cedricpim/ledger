# Class responsible for loading the ledger file into memory and storing all the
# transactions. It can also be queried to retrieve information regarding these
# transactions in several different ways.
class Ledger
  extend Forwardable

  def_delegators :content, :accounts, :categories, :currencies,
    :descriptions, :travels, :trips, :report, :currency_per_account

  attr_accessor :transactions

  def initialize
    @transactions = []
  end

  def load!
    handle_encryption do |file|
      CSV.foreach(file, headers: true) do |row|
        self.transactions << Transaction.new(*row.fields)
      end
    end
  end

  def add!
    transaction = TransactionBuilder.new(self).build!

    handle_encryption do |file|
      File.open(file, 'a') { |f| f.write("#{transaction.to_ledger}\n") }
      File.write(file, File.read(file).gsub(/\n+/,"\n"))
    end
  end

  def create!
    return if File.exist?(filepath)

    CSV.open(filepath, 'wb') { |csv| csv << FIELDS }
    encryption { |cipher| cipher.encrypt }
  end

  def open!
    handle_encryption { |file| system("#{ENV['EDITOR']} #{file.path}") }
  end

  private

  # Rescue from OpenSSL::Cipher::CipherError when trying to decrypt an already
  # decrypted file.
  def handle_encryption
    encryption(file, tempfile) { |cipher| cipher.decrypt }
    yield(tempfile)
    encryption(tempfile, file) { |cipher| cipher.encrypt }
  rescue OpenSSL::Cipher::CipherError
    yield(file)
    encryption { |cipher| cipher.encrypt }
  end

  def encryption(source = file, target = file)
    return unless ENCRYPTION

    cipher = OpenSSL::Cipher.new(ENCRYPTION_ALGORITHM)
    yield cipher
    cipher.pkcs5_keyivgen(*credentials)
    result = cipher.update(File.read(source))
    result << cipher.final
    File.open(target, 'w') { |file| file.write(result) }
  end

  def credentials
    [`#{ENV['LEDGER_PASSWORD']}`, `#{ENV['LEDGER_SALT']}`].map(&:chomp)
  end

  def content
    @content ||=
      begin
        load!
        Content.new(transactions)
      end
  end

  def file
    @file ||= File.new(filepath)
  end

  def filepath
    File.expand_path(ENV['LEDGER'])
  end

  def tempfile
    @tempfile ||= ENCRYPTION ? Tempfile.new : file
  end
end
