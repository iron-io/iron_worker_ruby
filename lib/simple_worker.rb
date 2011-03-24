require 'appoxy_api'
require 'active_support/core_ext'
require_relative 'simple_worker/service'
require_relative 'simple_worker/base'
require_relative 'simple_worker/config'
require_relative 'simple_worker/used_in_worker'


module SimpleWorker

  class << self
    attr_accessor :config,
                  :service

    def configure()
      yield(config)
      SimpleWorker.service = Service.new(config.access_key, config.secret_key, :config=>config)
    end

    def config
      @config ||= Config.new
    end
 
  end



end

if defined?(Rails)
#  puts 'Rails=' + Rails.inspect
#  puts 'vers=' + Rails::VERSION::MAJOR.inspect
  if Rails::VERSION::MAJOR == 2
    require_relative 'rails2_init.rb'
  else
    require_relative 'railtie'
  end
end
