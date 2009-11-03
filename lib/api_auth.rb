module SimpleWorker
    attr_accessor :host
    class ApiAuth
        def initialize(access_key, secret_key, options={})
            @access_key = access_key
            @secret_key = secret_key
            @host = options[:host] || "http://simpleworker.appoxy.com/api/"

        end
    end

end
