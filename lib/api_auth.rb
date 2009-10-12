module SimpleWorker
    class ApiAuth
        def initialize(access_key, secret_key)
            @access_key = access_key
            @secret_key = secret_key
            @host = "http://simpleworker.appoxy.com/api/"

        end
    end

end
