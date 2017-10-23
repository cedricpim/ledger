# Class responsible for holding all the logic related to encrypting and
# decrypting the ledger file.
class Encryption
  # Rescue from OpenSSL::Cipher::CipherError when trying to decrypt an already
  # decrypted file.
  def wrap
    decrypt!(file, tempfile)
    yield(tempfile)
    encrypt!(tempfile, file)
  rescue OpenSSL::Cipher::CipherError
    yield(file)
    encrypt!
  end

  def encrypt!(source = file, target = file)
    cipher(source, target) { |cipher| cipher.encrypt }
  end

  def decrypt!(source = file, target = file)
    cipher(source, target) { |cipher| cipher.decrypt }
  end

  private

  def cipher(source, target)
    return unless encryption[:enabled]

    cipher = OpenSSL::Cipher.new(encryption[:algorithm])
    yield cipher
    cipher.pkcs5_keyivgen(*credentials)
    result = cipher.update(File.read(source))
    result << cipher.final
    File.open(target, 'w') { |file| file.write(result) }
  end

  def file
    @file ||= File.new(File.expand_path(CONFIGS[:ledger]))
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
