require 'rest_client'

module SimpleWorker
  module Api

    module Signatures


      def self.generate_timestamp(gmtime)
        return gmtime.strftime("%Y-%m-%dT%H:%M:%SZ")
      end


      def self.generate_signature(operation, timestamp, secret_key)
        my_sha_hmac = Digest::HMAC.digest(operation + timestamp, secret_key, Digest::SHA1)
        my_b64_hmac_digest = Base64.encode64(my_sha_hmac).strip
        return my_b64_hmac_digest
      end


      def self.hash_to_s(hash)
        str = ""
        hash.sort.each { |a| str+= "#{a[0]}#{a[1]}" }
        #removing all characters that could differ after parsing with rails
        return str.delete "\"\/:{}[]\' T"
      end
    end

    # Subclass must define:
    #  host: endpoint url for service
    class Client

      @@logger = Logger.new(STDOUT)
      @@logger.level = Logger::INFO

      def self.logger
        @@logger
      end

      attr_accessor :host, :access_key, :secret_key, :version

      def initialize(host, access_key, secret_key, options={})
        @host = host
        @access_key = access_key
        @secret_key = secret_key
      end

      def process_ex(ex)
        body = ex.http_body
        @@logger.debug 'EX BODY=' + body.to_s
        decoded_ex = JSON.parse(body)
        exception = Exception.new(ex.message + ": " + decoded_ex["msg"])
        exception.set_backtrace(decoded_ex["backtrace"].split(",")) if decoded_ex["backtrace"]
        raise exception
      end

      def get(method, params={}, options={})
        begin
#                ClientHelper.run_http(host, access_key, secret_key, :get, method, nil, params)
          parse_response RestClient.get(append_params(url(method), add_params(method, params)), headers), options
        rescue RestClient::Exception  => ex
          process_ex(ex)
        end
      end

      def post_file(method, file, params={}, options={})
        begin
          parse_response RestClient.post(url(method), add_params(method, params).merge!({:file=>file}), :multipart => true), options
        rescue RestClient::Exception  => ex
          process_ex(ex)
        end
      end

      def post(method, params={}, options={})
        begin
          parse_response RestClient.post(url(method), add_params(method, params).to_json, headers), options
          #ClientHelper.run_http(host, access_key, secret_key, :post, method, nil, params)
        rescue RestClient::Exception  => ex
          process_ex(ex)
        end
      end


      def put(method, body, options={})
        begin
          parse_response RestClient.put(url(method), add_params(method, body).to_json, headers), options
          #ClientHelper.run_http(host, access_key, secret_key, :put, method, body, nil)
        rescue RestClient::Exception  => ex
          process_ex(ex)
        end
      end

      def delete(method, params={}, options={})
        begin
          parse_response RestClient.delete(append_params(url(method), add_params(method, params))), options
        rescue RestClient::Exception => ex
          process_ex(ex)
        end
      end

      def url(command_path)
        url = host + command_path
        url
      end

      def add_params(command_path, hash)
        v = version||"0.1"
        ts = SimpleWorker::Api::Signatures.generate_timestamp(Time.now.gmtime)
        # puts 'timestamp = ' + ts
        sig = case v
                when "0.2"
                  SimpleWorker::Api::Signatures.generate_signature(command_path + SimpleWorker::Api::Signatures.hash_to_s(hash), ts, secret_key)
                when "0.1"
                  SimpleWorker::Api::Signatures.generate_signature(command_path, ts, secret_key)
              end

        extra_params = {'sigv'=>v, 'sig' => sig, 'timestamp' => ts, 'access_key' => access_key}
        hash.merge!(extra_params)
      end

      def append_params(host, params)
        host += "?"
        i = 0
        params.each_pair do |k, v|
          host += "&" if i > 0
          host += k + "=" + CGI.escape(v)
          i +=1
        end
        return host
      end

      def headers
        user_agent = "SimpleWorker Ruby Client"
        headers = {'User-Agent' => user_agent}
      end

      def parse_response(response, options={})
#        puts 'PARSE RESPONSE!'
        unless options[:parse] == false
          begin
            return JSON.parse(response.to_s)
          rescue => ex
            puts 'response that caused error = ' + response.to_s
            raise ex
          end
        else
          response
        end
      end

    end

  end

end
