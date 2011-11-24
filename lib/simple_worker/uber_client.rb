# This is a simple wrapper that can use different http clients depending on what's installed.
# The purpose of this is so that users who can't install binaries easily (like windoze users) can have fallbacks that work.


module Uber
  def self.gem=(g)
    @gem = g
  end

  def self.gem
    @gem
  end

  begin
    require 'typhoeus'
    Uber.gem = :typhoeus
  rescue LoadError => ex
    puts "Could not load typhoeus. #{ex.class.name}: #{ex.message}. Falling back to rest-client. Please install 'typhoeus' gem for best performance."
    require 'rest_client'
    Uber.gem = :rest_client
  end

  class RestClientResponseWrapper
    def initialize(response)
      @response = response
    end

    def code
      @response.code
    end

    def body
      @response.body
    end

  end

  class ClientError < StandardError
    
  end

  class RestClientExceptionWrapper < ClientError
    def initialize(ex)
      super(ex.message)
      @ex = ex
    end
  end

  class TimeoutError < ClientError
    def initialize(msg=nil)
      msg ||= "HTTP Request Timed out."
      super(msg)
    end
  end

  class TyphoeusTimeoutError < TimeoutError
    def initialize(response)  
      msg ||= "HTTP Request Timed out. Curl code: #{response.curl_return_code}. Curl error msg: #{response.curl_error_message}."
      super(msg)
    end
  end

  class Client

    def initialize

    end

    def get(url, req_hash={})
      if Uber.gem == :typhoeus
        req_hash[:connect_timeout] = 5000
        req_hash[:timeout] ||= 10000
        # puts "REQ_HASH=" + req_hash.inspect
        response = Typhoeus::Request.get(url, req_hash)
        #p response
        if response.timed_out?
          raise TyphoeusTimeoutError.new(response)
        end
      else
        begin
          headers = req_hash[:headers] || {}
          r2 = RestClient.get(url, req_hash.merge(headers))
          response = RestClientResponseWrapper.new(r2)
            # todo: make generic exception
        rescue RestClient::Exception => ex
          raise RestClientExceptionWrapper.new(ex)
        end
      end
      response
    end

    def post(url, req_hash={})
      if Uber.gem == :typhoeus
        # todo: should change this timeout to longer if it's for posting file
        req_hash[:connect_timeout] = 5000
        req_hash[:timeout] ||= 10000
        # puts "REQ_HASH=" + req_hash.inspect
        response = Typhoeus::Request.post(url, req_hash)
        #p response
        if response.timed_out?
          raise TyphoeusTimeoutError.new(response)
        end
      else
        begin
          headers = req_hash[:headers] || {}
          r2 = RestClient.post(url, req_hash[:body], headers)
          response = RestClientResponseWrapper.new(r2)
            # todo: make generic exception
        rescue RestClient::Exception => ex
          raise RestClientExceptionWrapper(ex)
        end
      end
      response
    end

  end
end