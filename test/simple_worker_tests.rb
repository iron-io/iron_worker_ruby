require 'test/unit'
require 'yaml'
require File.join(File.dirname(__FILE__), '../lib/simple_worker')

class SimpleWorkerTests < Test::Unit::TestCase

    def setup
        @config = YAML::load(File.open(File.expand_path("~/.test-configs/simple_worker.yml")))
        #puts @config.inspect
        @access_key = @config['simple_worker']['access_key']
        @secret_key = @config['simple_worker']['secret_key']

        @worker = SimpleWorker::Service.new(@access_key, @secret_key)
        @worker.host = "http://localhost:3000/api/"
    end

    def teardown

    end

    def test_queue


        # Upload latest runner code
        @worker.upload(File.join(File.dirname(__FILE__), "./test_runner.rb"), "TestWorker")

        # Add something to queue, get task ID back
        # Single task
        response_hash_single = @worker.queue("TestRunner", {"s3_key"=>"single runner", "times"=>10})

        # task set
        response_hash = @worker.queue("TestRunner", [{"id"=>"local_id", "s3_key"=>"some key", "times"=>4}, {"s3_key"=>"some key2", "times"=>3}, {"s3_key"=>"some key", "times"=>2}])
#
        # Check status
        tasks = response_hash["tasks"]
        while tasks.size > 0
            tasks.each do |t|
                status_response = @worker.status(t["task_id"])
                puts 'status for ' + t["task_id"] + ' = ' + status_response["status"]
                if status_response["status"] == "complete" || status_response["status"] == "error" || status_response["status"] == "cancelled"
                    tasks.delete(t)
                end
            end
        end

        # lets try to get the log now too
        task_id = response_hash_single["tasks"][0]["task_id"]
        puts 'task_id=' + task_id
        puts 'log=' + @worker.log(task_id).inspect

    end

    def test_scheduled

        # Upload latest runner code
        @worker.upload(File.join(File.dirname(__FILE__), "./scheduled_runner.rb"), "ScheduledWorker")

        start_at = 10.seconds.since
        #start_at = start_at.gmtime # testing different timezone
        puts 'start_at =' + start_at.inspect
        response_hash = @worker.schedule("TestRunner", {"msg"=>"One time test."}, {:start_at=>start_at})
        puts 'response_hash=' + response_hash.inspect

        start_at = 10.seconds.since
        response_hash = @worker.schedule("TestRunner", {"msg"=>"Run times test"}, {:start_at=>start_at, :run_every=>30, :run_times=>3})
        puts 'response_hash=' + response_hash.inspect

        start_at = 10.seconds.since
        end_at = 2.minutes.since
        response_hash = @worker.schedule("TestRunner", {"msg"=>"End at test"}, {:start_at=>start_at, :run_every=>30, :end_at=>end_at, :run_times=>20})
        puts 'response_hash=' + response_hash.inspect

    end
end

