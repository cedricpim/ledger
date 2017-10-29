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
    cipher(source, target, &:encrypt)
  end

  def decrypt!(source = file, target = file)
    cipher(source, target, &:decrypt)
  end

  private

  def cipher(source, target)
    return unless CONFIG.encryption[:enabled]

    cipher = OpenSSL::Cipher.new(CONFIG.encryption[:algorithm])
    yield cipher
    cipher.pkcs5_keyivgen(*CONFIG.credentials)
    result = cipher.update(File.read(source))
    result << cipher.final
    File.open(target, 'w') { |file| file.write(result) }
  end

  def file
    @file ||= File.new(File.expand_path(CONFIG.ledger))
  end

  def tempfile
    @tempfile ||= CONFIG.encryption[:enabled] ? Tempfile.new : file
  end
end
