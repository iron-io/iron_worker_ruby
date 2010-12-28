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
            SimpleWorker.config ||= Config.new
            yield(config)
            SimpleWorker.service = Service.new(config.access_key, config.secret_key, :config=>config)
        end
    end

end