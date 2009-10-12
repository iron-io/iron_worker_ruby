require 'http_enabled'
require 'api_auth'

module SimpleWorker
    class Queue < SimpleWorker::ApiAuth

        extend SimpleWorker::HttpEnabled

        def initialize(access_key, secret_key, class_name)
            super(access_key, secret_key)
            @class_name = class_name
        end

        def add(class_name, data={})

            params = nil
            if !data.is_a?(Array)
                data = [data]
            end
            hash_to_send = {}
            hash_to_send["data"] = data
            hash_to_send["class_name"] = class_name
            puts 'hash_to_send=' + hash_to_send.inspect
            res = run_http(access_key, secret_key, :put, "queue/add", hash_to_send, params)
            puts "response=" + res
            return ActiveSupport::JSON.decode(res)
        end


    end


end