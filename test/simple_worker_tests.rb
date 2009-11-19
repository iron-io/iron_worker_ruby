require 'test/unit'
require 'yaml'
require File.join(File.dirname(__FILE__), '../lib/simple_worker')

class SimpleWorkerTests < Test::Unit::TestCase

    def setup
        @config = YAML::load(File.open(File.expand_path("~/.test-configs/simple_worker.yml")))
        #puts @config.inspect
        @access_key = @config['simple_worker']['access_key']
        @secret_key = @config['simple_worker']['secret_key']
    end

    def teardown

    end

    def test_queue

        worker = SimpleWorker::Service.new(@access_key, @secret_key)

        # Upload latest runner code
        worker.upload(File.join(File.dirname(__FILE__), "./test_runner.rb"), "TestRunner")

        # Add something to queue, get task ID back
        # Single task
        response_hash = worker.queue("TestRunner", {"s3_key"=>"single runner", "times"=>10})
        # task set
        response_hash = worker.queue("TestRunner", [{"id"=>"local_id", "s3_key"=>"some key", "times"=>4}, {"s3_key"=>"some key2", "times"=>3}, {"s3_key"=>"some key", "times"=>2}])

        # Check status
        tasks = response_hash["tasks"]
        while tasks.size > 0
            tasks.each do |t|
                status_response = worker.status(t["task_id"])
                puts 'status for ' + t["task_id"] + ' = ' + status_response["status"]
                if status_response["status"] == "complete"
                    tasks.delete(t)
                end
            end
        end


    end
end

