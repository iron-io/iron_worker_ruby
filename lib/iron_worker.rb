require_relative 'iron_worker/utils'
require_relative 'iron_worker/service'
require_relative 'iron_worker/base'
require_relative 'iron_worker/config'
require_relative 'iron_worker/used_in_worker'


module IronWorker
  @@logger = Logger.new(STDOUT)
  @@logger.level = Logger::INFO


  class << self
    attr_accessor :config,
                  :service

    def configure()
      yield(config)
      if config && config.token
        IronWorker.service ||= Service.new(config.token, :config=>config)
      else
        @@logger.warn "No token specified in configure, be sure to set it!"
      end
    end

    def config
      @config ||= Config.new
    end

    def logger
      @@logger
    end

    def api_version
      2
    end
  end

end

if defined?(Rails)
#  puts 'Rails=' + Rails.inspect
#  puts 'vers=' + Rails::VERSION::MAJOR.inspect
  if Rails::VERSION::MAJOR == 2
    require_relative 'iron_worker/rails2_init.rb'
  else
    require_relative 'iron_worker/railtie'
  end
end
