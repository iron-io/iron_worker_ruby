require 'rest_client'
require 'patron'

module SimpleWorker

  class Error < StandardError
    def initialize(msg, options={})
      super(msg)
      @options = options
    end

    def status
      @options[:status]
    end
  end

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

      attr_accessor :scheme, :host, :port, :token, :version, :config

      def initialize(host, token, options={})
        @config = options[:config]
        @scheme = options[:scheme] || @config.scheme || "https"
        @host = options[:host] || @config.host || host
        @port = options[:port] || @config.port || 443
        @token = options[:token] || @config.token || token
        @version = options[:version]
        @logger = options[:logger]

        @base_url = "#{@scheme}://#{@host}:#{@port}/#{@version}"

        sess = Patron::Session.new
        sess.timeout = 10
        sess.base_url = @base_url
        sess.headers['User-Agent'] = 'IronMQ Ruby Client'
        #sess.enable_debug "/tmp/patron.debug"
        @http_sess = sess


      end


      def base_url
        @base_url
      end

      def url(command_path)
        url = "#{base_url}/#{command_path}"
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

      def check_response(response, options={})
        status = response.status
        body = response.body
        res = nil
        unless options[:parse] == false
          res = JSON.parse(body)
        end
        if status < 400

        else
          raise SimpleWorker::Error.new((res ? "#{status}: #{res["msg"]}" : "#{status} Error! parse=false so no msg"), :status=>status)
        end
        res || body
      end

      def get(method, params={}, options={})
        full_url = url(method)
        all_params = add_params(method, params)
        url_plus_params = append_params(full_url, all_params)
        @logger.debug 'get url=' + url_plus_params
        response = @http_sess.request(:get, url_plus_params,
                                      {},
                                      {})
        check_response(response, options)
        body = response.body
        parse_response(body, options)

      end

      def post_file(method, file, params={}, options={})
        begin
          data = add_params(method, params).to_json
          url = url(method) + "?oauth=" + token
          @logger.debug "post_file url = " + url
          @logger.debug "data = " + data
          @logger.debug "params = " + params.inspect
          @logger.debug "options = " + options.inspect
          # todo: replace with patron
          parse_response(RestClient.post(append_params(url(method), add_params(method, params)), {:data => data, :file => file}, :content_type => 'application/json'), options)
        rescue Exception => ex
          process_ex(ex)
        end
      end

      def post(method, params={}, options={})
        @logger.debug "params = " + params.inspect
        @logger.debug "options = " + options.inspect
        @logger.debug "params.payload = " + params[:payload].inspect
        @logger.debug "token = "+ token.inspect
        begin
          url = url(method) + "?oauth=" + token
          @logger.debug 'post url=' + url
          response = @http_sess.post(url, add_params(method, params).to_json, {"Content-Type" => 'application/json'})
          check_response(response)
          @logger.debug 'response: ' + response.inspect
          body = response.body
          parse_response(body, options)
        rescue Exception => ex
          @logger.warn("Exception in post! #{ex.message}")
          @logger.warn(ex.backtrace.join("\n"))
          process_ex(ex)
        end
      end


      def put(method, body, options={})
        begin
          # todo: replace with patron
          parse_response RestClient.put(url(method), add_params(method, body).to_json, headers), options
        rescue RestClient::Exception => ex
          process_ex(ex)
        end
      end

      def delete(method, params={}, options={})
        begin
          # todo: replace with patron
          parse_response RestClient.delete(append_params(url(method), add_params(method, params))), options
        rescue RestClient::Exception => ex
          process_ex(ex)
        end
      end

      def add_params(command_path, hash)
        extra_params = {'oauth' => token}
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
