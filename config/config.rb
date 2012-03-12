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
        db_sync: 's3',

        # sqlite config options 
        sqlite_path: '/home/ubuntu/client-daemon/key-mgmt-server/sqlite.db',

        # AWS S3 config options
        s3_access_key_id: 'AKIAIA2RP3QAYPMTY7WA',
        s3_secret_access_key: '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',
        s3_bucketname: 'keybucket',
        s3_dbname:      'key_db' # the filename of the db in teh bucket

    }.each do |k,v|
        KeyServer::Config.instance[k] = v
    end

end

