gem 'test-unit'
require 'test/unit'
require 'yaml'
begin
  require File.join(File.dirname(__FILE__), '../lib/simple_worker')
rescue Exception => ex
  puts "Could NOT load current simple_worker: " + ex.message
  #require 'simple_worker'
  raise ex
end

SimpleWorker.logger.level = Logger::DEBUG

require_relative "test_worker"
require_relative "test_worker_2"
require_relative "test_worker_3"

class TestBase < Test::Unit::TestCase

  def setup
    @config = YAML::load(File.open(File.expand_path("~/.test_configs/simple_worker.yml")))
    #puts @config.inspect
    @access_key = @config['simple_worker']['access_key']
    @secret_key = @config['simple_worker']['secret_key']

    # new style
    SimpleWorker.configure do |config|
      config.access_key = @access_key
      config.secret_key = @secret_key
      config.host = @config['simple_worker']['host']
      config.global_attributes["db_user"] = "sa"
      config.global_attributes["db_pass"] = "pass"

    end
  end

  def wait_for_task(params={})
    tries = 0
    status = nil
    sleep 1
    while  tries < 60
      status = status_for(params)
      puts 'status = ' + status.inspect
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
