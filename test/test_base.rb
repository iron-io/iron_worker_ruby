require 'test/unit'
require 'yaml'
begin
  require File.join(File.dirname(__FILE__), '../lib/simple_worker')
rescue Exception => ex
  puts "Could NOT load current simple_worker: " + ex.message
  require 'simple_worker'
end
require_relative "test_worker"
require_relative "test_worker_2"
require_relative "test_worker_3"

class TestBase < Test::Unit::TestCase

  def setup
    @config     = YAML::load(File.open(File.expand_path("~/.test_configs/simple_worker.yml")))
    #puts @config.inspect
    @access_key = @config['simple_worker']['access_key']
    @secret_key = @config['simple_worker']['secret_key']

    # new style
    SimpleWorker.configure do |config|
      config.access_key                   = @access_key
      config.secret_key                   = @secret_key
#            config.host = "http://localhost:3000/api/"
      config.global_attributes["db_user"] = "sa"
      config.global_attributes["db_pass"] = "pass"
      config.database = {
          :adapter  => "mysql2",
          :host     => "localhost",
          :database => "appdb",
          :username => "appuser",
          :password => "secret"
      }

    end
  end
end