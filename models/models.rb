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
            @@ciphers = Set.new %w(aes-128-cbc aes-128-ecb aes-192-cbc
        aes-192-ecb aes-256-cbc aes-256-ecb bf bf-cbc bf-cfb bf-ecb bf-ofb
        camellia-128-cbc camellia-128-ecb camellia-192-cbc camellia-192-ecb
        camellia-256-cbc camellia-256-ecb)

            @@ciphers.include?(type)
        end
    end




end
