require 'singleton'
require 'yaml'

module KeyServer
    class Config
        include Singleton

        attr_accessor :config

        def initialize
            @config = Hash.new
        end

        def [](key)
            @config[key]
        end

        def []=(key, val)
            @config[key] = val
        end
    end

    # configuration options
    {
        # administrator user configuration
        admin_username: 'admin',
        admin_email:    'admin@example.com',
        admin_password: 'asdfgh123',

        #
        # Database config
        #
        db_type: 'sqlite',
        db_backup: 's3',

        # sqlite config options 
        sqlite_path: '/home/ubuntu/client-daemon/key-mgmt-server/db/sqlite.db',

        # AWS S3 config options
        s3_access_key_id:           ENV['AMAZON_ACCESS_KEY_ID'],
        s3_secret_access_key:       ENV['AMAZON_SECRET_ACCESS_KEY'],
        s3_bucketname:              'keybucket',
        s3_dbname:                  'key_db', # the filename of the db in the bucket
        s3_db_encrypt:              'yes', # encrypt/decrypt data in S3 storage
        s3_db_encryption_cipher:    'aes-256-cbc', # one of the modes from model.rb
        s3_db_encryption_key:       ENV['DB_ENCRYPTION_KEY'],  # hex
        s3_db_encryption_iv:        ENV['DB_ENCRYPTION_IV'] # hex

    }.each do |k,v|
        KeyServer::Config.instance[k] = v
    end

end

