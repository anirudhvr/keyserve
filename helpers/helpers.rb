require 'openssl'
require 'base64'

module KeyServer::Helpers

    def protected!
        user = authorized?
        if user.nil?
            response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
            throw(:halt, [401, "Not authorized\n"])
        else 
            return user
        end
    end

    def authorized?
        @auth ||=  Rack::Auth::Basic::Request.new(request.env)

        if @auth.provided? && @auth.basic? && @auth.credentials 
            u = User.first(api_key: @auth.credentials[0]) # password ignored because username is the api_key
            puts "Found user: #{u.name}" unless u.nil?
            return u
        else
            return nil
        end
    end

    # stolen from http://github.com/cschneid/irclogger/blob/master/lib/partials.rb
    #   and made a lot more robust by me
    # this implementation uses erb by default. if you want to use any other template mechanism
    #   then replace `erb` on line 13 and line 17 with `haml` or whatever 
    def partial(template, *args)
        template_array = template.to_s.split('/')
        template = template_array[0..-2].join('/') + "/_#{template_array[-1]}"
        options = args.last.is_a?(Hash) ? args.pop : {}
        options.merge!(:layout => false)
        locals = options[:locals] || {}
        if collection = options.delete(:collection) then
            collection.inject([]) do |buffer, member|
                buffer << erb(:"#{template}", options.merge(:layout => false, 
                        :locals => {template_array[-1].to_sym => member}.merge(locals)))
            end.join("\n")
        else
            erb(:"#{template}", options)
        end
    end
end
