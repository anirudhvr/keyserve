require 'openssl'
require 'base64'
require 'securerandom'
require 'set'

ciphers = Set.new %w(aes-128-cbc aes-128-ecb aes-192-cbc aes-192-ecb 
aes-256-cbc aes-256-ecb bf bf-cbc bf-cfb bf-ecb bf-ofb 
camellia-128-cbc camellia-128-ecb camellia-192-cbc 
camellia-192-ecb camellia-256-cbc camellia-256-ecb)

unless ciphers.include?(ARGV[0])
    $stderr.puts "Usage: #{$0} <ciphername>, where cipher is one of the" + 
    " following\n\t[" + ciphers.to_a.join(', ') + "]"
    exit
end

c = OpenSSL::Cipher.new(ARGV[0])
key = c.random_key
iv = c.random_iv

puts "Key: #{Base64.encode64(key)}, IV: #{Base64.encode64(iv)}"

