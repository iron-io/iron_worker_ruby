require 'test/unit'
require 'yaml'
begin
    require File.join(File.dirname(__FILE__), '../lib/simple_worker')
rescue Exception => ex
    puts ex.message
    require 'simple_worker'
end
require File.join(File.dirname(__FILE__), "./test_worker")
require File.join(File.dirname(__FILE__), "./test_worker_2")
require File.join(File.dirname(__FILE__), "./test_worker_3")

class TestBase < Test::Unit::TestCase

    def setup
        @config = YAML::load(File.open(File.expand_path("~/.test-configs/simple_worker.yml")))
        #puts @config.inspect
        @access_key = @config['simple_worker']['access_key']
        @secret_key = @config['simple_worker']['secret_key']

        @worker = SimpleWorker::Service.new(@access_key, @secret_key)
        @worker.host = "http://localhost:3000/api/"

        # new style
        SimpleWorker.configure do |config|
            config.access_key = @access_key
            config.secret_key = @secret_key
            config.host = "http://localhost:3000/api/"
        end
    end
end