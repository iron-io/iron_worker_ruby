require "rubygems"
require "bundler/setup"

gem 'test-unit'
require 'test/unit'
require 'yaml'
require 'uber_config'
begin
  require File.join(File.dirname(__FILE__), '../lib/iron_worker')
rescue Exception => ex
  puts "Could NOT load current iron_worker: " + ex.message
  raise ex
end

#IronWorker.logger.level = Logger::DEBUG
IronWorker.service=nil
IronWorker.config.merged_gems={}


require_relative "workers/iw_test_worker"
require_relative "workers/iw_test_worker_2"
require_relative "workers/iw_test_worker_3"

class TestBase < Test::Unit::TestCase

  def setup
    @config = UberConfig.load
    puts "config: " + @config.inspect
    raise "Config is nil! Ensure you have a config file in the proper place." if @config.nil?

    @token = @config['iron']['token']
    @project_id = @config['iron']['project_id']
    # new style
    IronWorker.configure do |config|
      config.token = @token
      config.project_id = @project_id
      config.host = @config['iron']['host'] if @config['iron']['host']
      config.port = @config['iron']['port'] if @config['iron']['port']
      config.scheme = @config['iron']['scheme'] if @config['iron']['scheme']
      config.global_attributes["db_user"] = "sa"
      config.global_attributes["db_pass"] = "pass"
      #config.database = @config["database"]
      config.force_upload = true
      # config.skip_auto_dependencies = true
    end
  end

  def puts_log(worker)
    puts "LOG START:"
    puts worker.get_log
    puts ":LOG END"
  end

  def wait_for_task(params={})
    tries = 0
    status = nil
    sleep 1
    while  tries < 60
      status = status_for(params)
      puts "status: #{status['status']} -- " + status.inspect
      if status["status"] == "complete" || status["status"] == "error"
        break
      end
      sleep 2
    end
    status
  end

  def status_for(ob)
    if ob.is_a?(Hash)
      ob[:schedule_id] ? WORKER.schedule_status(ob[:schedule_id]) : WORKER.status(ob[:task_id])
    else
      ob.status
    end
  end


end
