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

  class Client

    def initialize

    end

    def get(url, req_hash={})
      if Uber.gem == :typhoeus
        response = Typhoeus::Request.get(url, req_hash)
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
        response = Typhoeus::Request.post(url, req_hash)
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