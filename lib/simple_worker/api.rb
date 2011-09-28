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

      attr_accessor :host, :port, :token, :version, :config

      def initialize(host, token, options={})
        @host = host
        @config = options[:config]
        @port = options[:port] || @config.port || 80
        @token = token
        @version = options[:version]
        @logger = options[:logger]

      end

      def url(command_path)
        url = "http://#{host}:#{port}/#{@version}/#{command_path}"
        # @logger.debug "url: " + url.to_s
        url
      end

      def process_ex(ex)
        body = ex.http_body
        @logger.debug 'EX http_code: ' + ex.http_code.to_s
        @logger.debug 'EX BODY=' + body.to_s
        decoded_ex = JSON.parse(body)
        exception = Exception.new(ex.message + ": " + decoded_ex["msg"])
        exception.set_backtrace(decoded_ex["backtrace"].split(",")) if decoded_ex["backtrace"]
        raise exception
      end

      def get(method, params={}, options={})
        #begin
#                ClientHelper.run_http(host, access_key, secret_key, :get, method, nil, params)
          full_url = url(method)
          all_params = add_params(method,params)

          url_plus_params = append_params(full_url, all_params)
          resp = RestClient.get(url_plus_params, headers)

          parse_response(resp, options)
        
          # Was: 
          #parse_response RestClient.get(append_params(url(method), add_params(method, params)), headers), options
        #rescue RestClient::Exception  => ex
        #  process_ex(ex)
        #end
      end

      def post_file(method, file, params={}, options={})
        begin
          #params.delete("runtime")
          #params["runtime"]='ruby'
          #params.delete("file_name")
          #params["file_name"] = "runner.rb"
          data = add_params(method, params).to_json
          @logger.debug "data = " + data
          @logger.debug "params = " + params.inspect
          @logger.debug "options = " + options.inspect
          token = params["oauth"]
          parse_response RestClient.post(url(method) + "?oauth="+token, {:data => data, :file => file}, :content_type => 'application/json', :accept => :json), options
          #parse_response(RestClient.post(append_params(url(method), add_params(method, params)), {:data => data, :file => file}, :content_type => 'application/json'), options)
        rescue RestClient::Exception  => ex
          process_ex(ex)
        end
      end

      def post(method, params={}, options={})
          @logger.debug "params = " + params.inspect
          @logger.debug "options = " + options.inspect
          @logger.debug "params.payload = " + params[:payload].inspect
          token = params["token"]
          @logger.debug "token = "+ token.inspect
        begin
          # here's what get() does:
          #parse_response RestClient.get(append_params(url(method), add_params(method, params)), headers), options
          parse_response(RestClient.post(url(method)+"?oauth="+token, add_params(method, params).to_json, headers.merge!({:content_type=>'application/json', :accept => "json"})), options)
          # was , add_params(method, params).to_json, headers.merge!({:content_type=>'application/json'})), options)
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

      def add_params(command_path, hash)
        v = version || "2.0"
        ts = SimpleWorker::Api::Signatures.generate_timestamp(Time.now.gmtime)
        extra_params = {'version'=>v, 'timestamp' => ts, 'oauth' => token}
        hash.merge!(extra_params)
      end

      def append_params(host, params)
        host += "?"
        i = 0
        params.each_pair do |k, v|
          #puts "k=#{k} v=#{v}"
          host += "&" if i > 0
          host += k + "=" + (v.is_a?(String) ? CGI.escape(v) : v.to_s)
          i +=1
        end
        return host
      end

      def headers
        user_agent = "SimpleWorker Ruby Client"
        headers = {'User-Agent' => user_agent}
      end

      def parse_response(response, options={})
        #puts 'PARSE RESPONSE: ' + response.to_s
        unless options[:parse] == false
          begin
            return JSON.parse(response.to_s)
          rescue => ex
            puts 'parse_response: response that caused error = ' + response.to_s
            raise ex
          end
        else
          response
        end
      end

    end

  end

end
