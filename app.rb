require 'sinatra/base'
require 'sinatra/reloader' if development?
require './config'
require './helpers'
require './models'
#require 'dm-redis-adapter'
require 'dm-sqlite-adapter'
require 'json'

include KeyServer::Models

class KeyMgmtServer < Sinatra::Base

    helpers do
        include KeyServer::Helpers
    end

    configure do 
        # ensure config files are read
        set :config, KeyServer::Config.instance

        register Sinatra::Reloader if development? 

        # set up data store
        set :dm_logger, DataMapper::Logger.new($stdout, :debug)
        #DataMapper.setup(:default, {adapter: "redis"})
        DataMapper.setup(:default, "sqlite://#{settings.config[:sqlite_path]}") 
        DataMapper.finalize
        DataMapper.auto_migrate! # wipes out existing data each time

        # set up a test user
        u = User.create(name: settings.config[:admin_username], email:
                        settings.config[:admin_email]) 
        k = Key.create(user: u, desc: "test key")
        puts "created user: #{u.name}, #{u.api_key}"
        puts "found user: #{User.first(api_key: u.api_key).nil? ?  'no' : 'yes'}"
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
            throw(:halt, [404, "Cannot find encryption keys for given API key"])
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
                throw(:halt, [401, "Not authorized\n"]) 
            end
        end

        userid = params[:userid]
        opts = Hash.new
        opts[:desc] = params[:desc] unless params[:desc].nil?
        opts[:type] = params[:type] unless params[:type].nil?
        u = User.get(userid.to_i)
        unless u.nil? || opts[:desc].strip.empty?
            if Key.create(opts.merge!({user: u}))
                return JSON.generate(kee = Key.all(fields: [:id, :desc,
                                                   :type, :key_str],
                                                   user: u))
            end
        end
        throw(:halt, [400, "Bad Request: parameter error"])
    end

    get '/key/:id' do
        user = protected!
        k = Key.first(id: params[:id])
        if k.nil?
            throw(:halt, [404, "Key id #{params[:id]} not found"])
        else
            k.update(last_access: Time.now)
            JSON.generate(k)
        end
    end

    delete '/key/:id' do
        user = protected!
        k = Key.first(id: params[:id])
        if k.nil?
            throw(:halt, [404, "Key id #{params[:id]} not found"])
        else
            if k.destroy
                "{OK}"
            else
                throw(:halt, [501, "Cannot destroy key id #{params[:id]}"])
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
