module Ledger
  # Class responsible for holding all the logic related to encrypting and
  # decrypting the ledger file.
  class Encryption
    FILE_MODE = 'r+'.freeze

    attr_reader :resource

    def initialize(resource)
      filepath = File.expand_path(resource)
      @resource = File.new(filepath, 'a') && File.new(filepath, FILE_MODE)
    end

    # Rescue from OpenSSL::Cipher::CipherError when trying to decrypt an already
    # decrypted file.
    def wrap
      decrypt!(resource, tempfile)
      yield(tempfile)
      encrypt!(tempfile, resource)
    rescue OpenSSL::Cipher::CipherError
      yield(resource)
      encrypt!
    end

    def encrypt!(source = resource, target = resource)
      cipher(source, target, &:encrypt)
    end

    def decrypt!(source = resource, target = resource)
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

    def tempfile
      @tempfile ||= CONFIG.encryption[:enabled] ? Tempfile.new : resource
    end
  end
end
