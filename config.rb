require 'singleton'

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
        # sqlite config options 
        sqlite_path: '/home/ubuntu/client-daemon/key-mgmt-server/sqlite.db',

        # redis config options
        redis_server: "localhost",
        redis_port:  6379,
        redis_apikey_db: 0,
        redis_user_db: 1,
        redis_key_db: 2,
        redis_log_db: 3,

        # administrator user configuration
        admin_username: 'admin',
        admin_email:    'admin@example.com',
        admin_password: 'asdfgh123'

    }.each do |k,v|
        KeyServer::Config.instance[k] = v
    end

end

