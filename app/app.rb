require 'sinatra/base'
require 'sinatra/reloader' if development?
require 'dm-sqlite-adapter'
require 'json'
require 'aws/s3'
require 'openssl'
require 'digest/md5'
require 'base64'

unless $LOAD_PATH.include?(File.expand_path(File.dirname(__FILE__ + "..")))
    $LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__ + "..")))
end

require 'config/config'
require 'helpers/helpers'
require 'models/models'

include KeyServer::Models

class KeyMgmtServer < Sinatra::Base

    def self.encrypt(cipher, key, iv, input)
        ciph = OpenSSL::Cipher.new(cipher)
        ciph.encrypt
        ciph.key = key
        ciph.iv = iv
        output = ciph.update(input) + ciph.final
    end

    def self.decrypt(cipher, key, iv, input)
        ciph = OpenSSL::Cipher.new(cipher)
        ciph.decrypt
        ciph.key = key
        ciph.iv = iv
        output = ciph.update(input) + ciph.final
    end

    helpers do
        include KeyServer::Helpers
    end

    configure do 
        # ensure config files are read
        set :config, KeyServer::Config.instance

        register Sinatra::Reloader if development? 

        # set up data store logging
        set :dm_logger, DataMapper::Logger.new($stdout, :debug)

        # move old copy of sqlite db, if it exists, to backup
        if File.exists?(settings.config[:sqlite_path])
            File.rename(settings.config[:sqlite_path],
                        settings.config[:sqlite_path] +
                        ".old.#{Time.now.to_i}")
        end

        # check to see if S3 database exists, and if so, pull it to local
        s3_retrieval_failed = true
        if settings.config[:s3_access_key_id] && settings.config[:s3_secret_access_key]
            AWS::S3::Base.establish_connection!(
                access_key_id: settings.config[:s3_access_key_id],
                secret_access_key: settings.config[:s3_secret_access_key], 
                use_ssl: true)
            if AWS::S3::Service.connected? && 
                AWS::S3::S3Object.exists?(settings.config[:s3_dbname], 
                                          settings.config[:s3_bucketname])
                key_db = AWS::S3::SS3Object.find(settings.config[:s3_dbname], 
                                                 settings.config[:s3_bucketname])
                unless key_db.nil?
                    puts "Retrieving DB from S3..."

                    # FIXME now assuming sqlite
                    fh = File.new(settings.config[:sqlite_path], 'wb')

                    # decrypt data if encrypted
                    if settings.config[:s3_db_encrypt] == 'yes' &&
                        !settings.config[:s3_db_encryption_key].nil? && 
                        !settings.config[:s3_db_encryption_iv].nil?
                        puts "Decrypting DB..."
                        decrypted = decrypt(settings.config[:s3_db_encryption_cipher],
                                            settings.config[:s3_db_encryption_key],
                                            settings.config[:s3_db_encryption_iv],
                                            key_db.value)
                        fh.write decrypted
                    else
                        fh.write key_db.value
                    end
                    fh.close
                    s3_retrieval_failed = false
                end
            end
        end

        DataMapper.setup(:default, "sqlite://#{settings.config[:sqlite_path]}")
        DataMapper.finalize

        # FIXME wipes out existing data each time if S3 retrieval failed
        if s3_retrieval_failed
            DataMapper.auto_migrate! 
            # set up an admin user
            u = User.create(name: settings.config[:admin_username], email:
                            settings.config[:admin_email], admin: true)
            k = Key.create(user: u, desc: "test key")
            puts "created user: #{u.name}, #{u.api_key}"
        end

        puts "found admin user: #{User.first.name}, #{User.first.api_key}"

    end

    at_exit do
        s3_push_failed = true
        if settings.config[:s3_access_key_id] && settings.config[:s3_secret_access_key]
            AWS::S3::Base.establish_connection!(
                access_key_id: settings.config[:s3_access_key_id],
                secret_access_key: settings.config[:s3_secret_access_key], 
                use_ssl: true)
            if AWS::S3::Service.connected?
                AWS::S3::Bucket.find(settings.config[:s3_bucketname]) rescue \
                    AWS::S3::Bucket.create(settings.config[:s3_bucketname]) 

                if File.exists?(settings.config[:sqlite_path]) 
                    db_contents = nil
                    # encrypt data if settings say sao
                    if settings.config[:s3_db_encrypt] == 'yes' &&
                        !settings.config[:s3_db_encryption_key].nil? && 
                        !settings.config[:s3_db_encryption_iv].nil?
                        file_contents = open(settings.config[:sqlite_path], "r").read
                        puts "Encrypting db..."
                        db_contents = encrypt(settings.config[:s3_db_encryption_cipher],
                                            settings.config[:s3_db_encryption_key],
                                            settings.config[:s3_db_encryption_iv],
                                            file_contents)
                    else
                        db_contents = open(settings.config[:sqlite_path], "rb").read
                    end

                    AWS::S3::S3Object.store(settings.config[:s3_dbname], 
                                   db_contents, settings.config[:s3_bucketname])
                    s3_push_failed = false
                end
            end
        end

        puts "Pushing to S3..." unless s3_push_failed
    end


    before do
    end

    after do 
    end

    # homepage
    get '/' do 
        erb :index
    end

    # viewing keys
    get '/keys'  do
        user = protected!
        kee = Key.all(fields: [:id, :desc, :type], user: user)
        unless kee.nil? || kee.empty?
            JSON.generate(kee)
        else
            throw(:halt, [404, "{Cannot find encryption keys for given API key}"])
        end
    end

    # creating new keys -- only admin is allowed
    post '/keys' do
        user = protected!
        # confirm that credentials are that of the admin
        if user.name == settings.config[:admin_username] 
            if (@auth.nil? || @auth.credentials[1].nil? || 
                @auth.credentials[1].strip.empty?  || 
                @auth.credentials[1] != settings.config[:admin_password])
                throw(:halt, [401, "{Not authorized}"]) 
            end
        end

        userid = params[:userid]
        opts = Hash.new
        opts[:desc] = params[:desc] unless params[:desc].nil?
        opts[:type] = params[:type] unless params[:type].nil?
        u = User.get(userid.to_i)
        unless u.nil? || opts[:desc].strip.empty?
            k = Key.create(opts.merge!({user: u}))
            if k.saved?
                return JSON.generate(k)
            else
                throw(:halt, [501, "{Internal server error}"])
            end
        end
        throw(:halt, [400, "{Bad Request: parameter error}"])
    end

    get '/key/:id' do
        user = protected!
        k = Key.first(id: params[:id])
        if k.nil?
            throw(:halt, [404, "{Key id #{params[:id]} not found}"])
        else
            k.update(last_access: Time.now)
            JSON.generate(k)
        end
    end

    delete '/key/:id' do
        user = protected!
        k = Key.first(id: params[:id])
        if k.nil?
            throw(:halt, [404, "{Key id #{params[:id]} not found}"])
        else
            if k.destroy
                "{OK}"
            else
                throw(:halt, [501, "{Cannot destroy key id #{params[:id]}}"])
            end
        end
    end


    # signup
    get '/signup' do
    end

    post '/signup' do
    end

    # signin
    get '/signin' do
    end

    post '/signin' do 
    end


end
