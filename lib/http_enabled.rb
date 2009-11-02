require 'rubygems'
require 'active_support'
require 'net/http'
require 'base64'


begin
    require 'digest/hmac'
    USE_EMBEDDED_HMAC = false
rescue
    puts "HMAC, not found in standard lib." + $!.message
    require 'hmac-sha1'
    USE_EMBEDDED_HMAC = true
end

module SimpleWorker

    DEFAULT_HOST = "http://simpleworker.appoxy.com/api/"

    module HttpEnabled


        def self.host
            return DEFAULT_HOST
        end


        # body is a hash
        def run_http(access_key, secret_key, http_method, command_path, body=nil, parameters={}, extra_headers=nil)
            ts = generate_timestamp(Time.now.gmtime)
            # puts 'timestamp = ' + ts
            sig = generate_signature_v0(command_path, ts, secret_key)
            # puts "My signature = " + sig
            url = SimpleWorker::HttpEnabled.host + command_path
            # puts url

            user_agent = "Ruby Client"
            headers = {'User-Agent' => user_agent}

            if !extra_headers.nil?
                extra_headers.each_pair do |k, v|
                    headers[k] = v
                end
            end

            extra_params = {'sigv'=>"0.1", 'sig' => sig, 'timestamp' => ts, 'access_key' => access_key}
            if http_method == :put
                body.update(extra_params)
            else
                parameters = {} if parameters.nil?
                parameters.update(extra_params)
#                puts 'params=' + parameters.inspect

            end


            uri = URI.parse(url)
            #puts 'body=' + body.to_s
            if (http_method == :put)
                req = Net::HTTP::Put.new(uri.path)
                body = ActiveSupport::JSON.encode(body)
                req.body = body unless body.nil?
            elsif (http_method == :post)
                req = Net::HTTP::Post.new(uri.path)
                if !parameters.nil?
                    req.set_form_data(parameters)
                else
                    req.body = body unless body.nil?
                end
            elsif (http_method == :delete)
                req = Net::HTTP::Delete.new(uri.path)
                if !parameters.nil?
                    req.set_form_data(parameters)
                end
            else
                req = Net::HTTP::Get.new(uri.path)
                if !parameters.nil?
                    req.set_form_data(parameters)
                end
            end
            headers.each_pair do |k, v|
                req[k] = v
            end
            # req.each_header do |k, v|
            # puts 'header ' + k + '=' + v
            #end
            res = Net::HTTP.start(uri.host, uri.port) do |http|
                http.request(req)
            end

            ret = ''
            case res
                when Net::HTTPSuccess
                    # puts 'response body=' + res.body
                    ret = res.body
                else
                    #res.error
                    puts 'HTTP ERROR: ' + res.class.name
                    puts res.body
                    ret = res.body
            end
            return ret
        end

        def generate_timestamp(gmtime)
            return gmtime.strftime("%Y-%m-%dT%H:%M:%SZ")
        end

        def generate_signature_v0(operation, timestamp, secret_access_key)
            if USE_EMBEDDED_HMAC
                my_sha_hmac = HMAC::SHA1.digest(secret_access_key, operation + timestamp)
            else
                my_sha_hmac = Digest::HMAC.digest(operation + timestamp, secret_access_key, Digest::SHA1)
            end
            my_b64_hmac_digest = Base64.encode64(my_sha_hmac).strip
            return my_b64_hmac_digest
        end
    end

end

