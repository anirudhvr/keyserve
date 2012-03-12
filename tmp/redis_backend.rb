require 'rubygems'
require 'redis'
require 'config'

module KeyServer
    class RedisStore
        def initialize
            c = KeyServer::Config.instance
            [:redis_apikey_db, :redis_user_db, :redis_key_db, :redis_log_db].each do |sym|
                instance_variable_set("@#{sym.to_s}".to_sym, 
                                      Redis.new(host: c[:redis_server], port: c[:redis_port], db: c[sym]))
                class << self
                    self
                end.class_eval do
                    attr_accessor sym
                end
            end
        end
    end
end
