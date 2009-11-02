require 'http_enabled'
require 'api_auth'

module SimpleWorker
    class Uploader < SimpleWorker::ApiAuth

        extend SimpleWorker::HttpEnabled

        def initialize(access_key, secret_key)
            super(access_key, secret_key)
        end

        # Options:
        #    - :callback_url
        def put(filename, class_name, data={})
            mystring = nil
            file = File.open(filename, "r") do |f|
                mystring = f.read
            end
            data = {"code"=>mystring, "class_name"=>class_name}
            puts "response=" + run_http(@access_key, @secret_key, :post, "code/put", nil, data)
            #puts "response=" + run_http(access_key, secret_key, :post, "queue/add", nil, data)
        end

    end
end


