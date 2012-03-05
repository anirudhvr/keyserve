require 'dm-validations'
require 'set'
require 'securerandom'

module KeyServer::Models
    class User
        include DataMapper::Resource

        property :id,           Serial 
        property :name,         String, :required => true, :index => true
        property :email,        String, :required => true, :index => true
        property :api_key,      String, 
            :required => true, 
            :index => true, 
            :default => lambda {|r,p| SecureRandom.hex(16) } # 128 bits 
        property :created_at,   DateTime, :default => Time.now
        property :last_access,  DateTime, :default => Time.now

        has n, :keys

        validates_uniqueness_of :email
        validates_uniqueness_of :api_key
    end

    class Key
        include DataMapper::Resource

        property :id,           Serial
        property :key_str,      String, 
            :required => true, 
            :index => true, 
            :default => lambda {|r,p| SecureRandom.hex(16) } # 128 bits 
        property :desc,         String, :required => true
        property :type,         String, :required => true, :default => 'aes-128-cbc'
        property :created_at,   DateTime, :default => Time.now
        property :last_access,  DateTime, :default => Time.now
        property :iv,           String
        property :salt,         String

        belongs_to :user

        validates_uniqueness_of :id
        validates_uniqueness_of :key_str
        validates_length_of :desc, :max => 20
        validates_with_block :type do 
            @@ciphers = Set.new %w(aes-128-cbc aes-128-ecb aes-192-cbc aes-192-ecb
            aes-256-cbc aes-256-ecb base64 bf bf-cbc bf-cfb bf-ecb
            bf-ofb camellia-128-cbc camellia-128-ecb camellia-192-cbc
            camellia-192-ecb camellia-256-cbc camellia-256-ecb cast
            cast-cbc cast5-cbc cast5-cfb cast5-ecb cast5-ofb des
            des-cbc des-cfb des-ecb des-ede des-ede-cbc des-ede-cfb
            des-ede-ofb des-ede3 des-ede3-cbc des-ede3-cfb des-ede3-ofb
            des-ofb des3 desx rc2 rc2-40-cbc rc2-64-cbc rc2-cbc rc2-cfb
            rc2-ecb rc2-ofb rc4 rc4-40 seed seed-cbc seed-cfb seed-ecb
            seed-ofb zlib)

            @@ciphers.include?(type)
        end
    end
end
