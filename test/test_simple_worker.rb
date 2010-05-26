require 'test/unit'
require 'yaml'
begin
    require File.join(File.dirname(__FILE__), '../lib/simple_worker')
rescue
    require 'simple_worker'
end
require File.join(File.dirname(__FILE__), "./test_worker")
require File.join(File.dirname(__FILE__), "./test_worker_2")

class SimpleWorkerTests < Test::Unit::TestCase

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

    def teardown

    end

    def test_new_worker_style
        # Add something to queue, get task ID back
        tw = TestWorker2.new
        tw.s3_key = "active style runner"
        tw.times = 3
        tw.x = true

        # schedule up a task
#        start_at = 10.seconds.since
#        response_hash_single = tw.schedule(:start_at=>start_at, :run_every=>30, :run_times=>3)
#        puts 'response_hash=' + response_hash_single.inspect
#
#        10.times do |i|
#            puts "status #{i}: " + tw.schedule_status.inspect
#        end

        # queue up a task
        response_hash_single = tw.queue
        puts 'response_hash=' + response_hash_single.inspect
        puts 'task_set_id=' + tw.task_set_id
        puts 'task_id=' + tw.task_id
        10.times do |i|
            puts "status #{i}: " + tw.status.inspect
            break if tw.status["status"] == "complete"
            sleep 2
        end

        assert tw.status["status"] == "complete"

    end


    def test_queue


        # Upload latest runner code
        @worker.upload(File.join(File.dirname(__FILE__), "./test_worker.rb"), "TestWorker")

        # Add something to queue, get task ID back
        # Single task
        response_hash_single = @worker.queue("TestWorker", {"s3_key"=>"single runner", "times"=>10})

        # task set
        response_hash = @worker.queue("TestWorker", [{"id"=>"local_id", "s3_key"=>"some key", "times"=>4}, {"s3_key"=>"some key2", "times"=>3}, {"s3_key"=>"some key", "times"=>2}])

         # Check status
        tasks = response_hash["tasks"]
        puts 'tasks.size=' + tasks.size.to_s
        while tasks.size > 0
            tasks.each do |t|
                puts "t=" + t.inspect
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
        status_with_log = @worker.log(task_id)
        puts 'log=' + status_with_log.inspect

    end

    def test_scheduled

        # Upload latest runner code
        @worker.upload(File.join(File.dirname(__FILE__), "./scheduled_worker.rb"), "ScheduledWorker")

        start_at = 10.seconds.since
        #start_at = start_at.gmtime # testing different timezone
        puts 'start_at =' + start_at.inspect
        response_hash = @worker.schedule("ScheduledWorker", {"msg"=>"One time test."}, {:start_at=>start_at})
        puts 'response_hash=' + response_hash.inspect

        start_at = 10.seconds.since
        response_hash = @worker.schedule("ScheduledWorker", {"msg"=>"Run times test"}, {:start_at=>start_at, :run_every=>30, :run_times=>3})
        puts 'response_hash=' + response_hash.inspect

        start_at = 10.seconds.since
        end_at = 2.minutes.since
        response_hash = @worker.schedule("ScheduledWorker", {"msg"=>"End at test"}, {:start_at=>start_at, :run_every=>30, :end_at=>end_at, :run_times=>20})
        puts 'response_hash=' + response_hash.inspect

    end

end

