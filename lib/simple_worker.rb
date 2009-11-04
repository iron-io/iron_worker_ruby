require File.join(File.dirname(__FILE__), 'http_enabled')
require File.join(File.dirname(__FILE__), 'api_auth')
require File.join(File.dirname(__FILE__), 'worker')

module SimpleWorker

    class Base < SimpleWorker::ApiAuth

        include SimpleWorker::HttpEnabled

        def initialize(access_key, secret_key, options={})
            super(access_key, secret_key, options)
        end

        # Options:
        #    - :callback_url
        def upload(filename, class_name, options={})
            mystring = nil
            file = File.open(filename, "r") do |f|
                mystring = f.read
            end
            options = {"code"=>mystring, "class_name"=>class_name}
            response = run_http(@host, @access_key, @secret_key, :post, "code/put", nil, options)
            puts "response=" + response
            return ActiveSupport::JSON.decode(response)
        end


        def queue(class_name, data={})

            params = nil
            if !data.is_a?(Array)
                data = [data]
            end
            hash_to_send = {}
            hash_to_send["data"] = data
            hash_to_send["class_name"] = class_name
            puts 'hash_to_send=' + hash_to_send.inspect
            response = run_http(@host, @access_key, @secret_key, :put, "queue/add", hash_to_send, params)
            puts "response=" + response
            return ActiveSupport::JSON.decode(response)
        end


        def status(task_id)
            data = {"task_id"=>task_id}
            #puts run_http(@access_key, @secret_key, :post, "queue/status", nil, {"task_id"=>@task_id})
            response = run_http(@host, @access_key, @secret_key, :get, "queue/status", nil, data)
            puts "response=" + response
            return ActiveSupport::JSON.decode(response)
        end

    end
end