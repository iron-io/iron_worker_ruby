module SimpleWorker
    class ClientError < StandardError

        attr_reader :response_hash

        def initialize(class_name, response_hash)
            puts 'response-hash=' + response_hash.inspect
            super("#{class_name} - #{response_hash["msg"]}")
            @response_hash = response_hash
        end
    end

    class ServiceError < StandardError
        attr_reader :body

        def initialize(class_name, body)
            super("#{class_name}")
            @body = body

        end
    end
end