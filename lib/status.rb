require 'http_enabled'
require 'api_auth'

module SimpleWorker
    class Status < SimpleWorker::ApiAuth

        extend SimpleWorker::HttpEnabled

        def initialize(access_key, secret_key, class_name)
            super(access_key, secret_key)
            @class_name = class_name
        end

        def check(task_id)
            data = {"task_id"=>task_id}
            #puts run_http(@access_key, @secret_key, :post, "queue/status", nil, {"task_id"=>@task_id})
            puts "response=" + run_http(@access_key, @secret_key, :get, "queue/status", nil, data)
        end
    end


end
