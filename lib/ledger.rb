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

    CSV.open(filepath, 'wb') { |csv| csv << CONFIGS[:fields].keys.map(&:capitalize) }
    apply_cipher { |cipher| cipher.encrypt }
  end

  def open!
    handle_encryption { |file| system("#{ENV['EDITOR']} #{file.path}") }
  end

  private

  # Rescue from OpenSSL::Cipher::CipherError when trying to decrypt an already
  # decrypted file.
  def handle_encryption
    apply_cipher(file, tempfile) { |cipher| cipher.decrypt }
    yield(tempfile)
    apply_cipher(tempfile, file) { |cipher| cipher.encrypt }
  rescue OpenSSL::Cipher::CipherError
    yield(file)
    apply_cipher { |cipher| cipher.encrypt }
  end

  def apply_cipher(source = file, target = file)
    return unless encryption[:enabled]

    cipher = OpenSSL::Cipher.new(encryption[:algorithm])
    yield cipher
    cipher.pkcs5_keyivgen(*credentials)
    result = cipher.update(File.read(source))
    result << cipher.final
    File.open(target, 'w') { |file| file.write(result) }
  end

  def content
    return @content if @content

    load!

    @content = Content.new(transactions)
  end

  def file
    @file ||= File.new(filepath)
  end

  def filepath
    File.expand_path(CONFIGS[:ledger])
  end

  def tempfile
    @tempfile ||= encryption[:enabled] ? Tempfile.new : file
  end

  def credentials
    [`#{encryption[:credentials][:password]}`, `#{encryption[:credentials][:salt]}`].compact.map(&:chomp)
  end

  def encryption
    CONFIGS[:encryption]
  end
end
