require 'openssl'
require 'base64'
require 'securerandom'

key = SecureRandom.hex(32)
puts "key is " + key
iv = SecureRandom.hex(8)

string = "some string"

# encrypt
c = OpenSSL::Cipher.new("aes-256-cbc")
c.encrypt
c.key = key
c.iv = iv
e = c.update(string)  + c.final
encrypted = Base64.encode64(e)

#decrypt
c = OpenSSL::Cipher.new("aes-256-cbc")
c.decrypt
c.key = key
c.iv = iv
msg = c.update(Base64.decode64(encrypted)) + c.final
puts "got message [#{msg}]"

