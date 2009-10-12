require 'test/unit'

class SimpleWorkerTests < Test::Unit::TestCase

    def setup
        @config = YAML::load(File.open(File.expand_path("~/.testconfigs/simple_worker.yml")))
        #puts @config.inspect
        @access_key = @config['simple_worker']['access_key']
        @secret_key = @config['simple_worker']['secret_key']
    end

    def teardown

    end

    def test_queue

        # Upload latest runner code
        uploader = SimpleWorker::Uploader.new(@access_key, @secret_key)
        uploader.put("../workers/test_runner.rb", "TestRunner")

        # Add something to queue, get task ID back
        queue = SimpleWorker::Queue.new(@access_key, @secret_key)
        # Single task
        response_hash = queue.add("TestRunner", {"s3_key"=>"single runner", "times"=>10})
        # task set
        response_hash = queue.add("TestRunner", [{"id"=>"local_id", "s3_key"=>"some key", "times"=>4}, {"s3_key"=>"some key2", "times"=>3}, {"s3_key"=>"some key", "times"=>2}])

        # Check status
        status = SimpleWorker::Status.new(@access_key, @secret_key)
        tasks = response_hash["tasks"]
        tasks.each do |t|
            status.check(t["task_id"])
        end


    end
end

