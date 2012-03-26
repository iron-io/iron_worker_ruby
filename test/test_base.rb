require "rubygems"
require "bundler/setup"

gem 'test-unit'
require 'test/unit'
require 'yaml'
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
    if defined? $abt_config
      @config = $abt_config
    else
      @config =YAML::load_file(File.expand_path(File.join("~", "Dropbox", "configs", "iron_worker_ruby", "test", "config.yml")))
    end
#    @config = YAML::load_file(File.join(File.dirname(__FILE__), "config.yml"))
    puts "config: " + @config.inspect

    @token = @config['iron_worker']['token']
    @project_id = @config['iron_worker']['project_id']
    # new style
    IronWorker.configure do |config|
      config.token = @token
      config.project_id = @project_id
      config.host = @config['iron_worker']['host'] if @config['iron_worker']['host']
      config.port = @config['iron_worker']['port'] if @config['iron_worker']['port']
      config.scheme = @config['iron_worker']['scheme'] if @config['iron_worker']['scheme']
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
