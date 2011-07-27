require 'active_record'
require_relative 'test_base'
require_relative 'cool_worker'
require_relative 'cool_model'
require_relative 'trace_object'
require_relative 'db_worker'

class SimpleWorkerTests < TestBase



  def test_gem_merging
    worker = GemDependencyWorker.new
    worker.queue
    status = worker.wait_until_complete
    p status
    assert status["status"] == "complete", "Status was not complete, it was #{status["status"]}"
    puts worker.get_log
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
    puts 'queuing ' + tw.inspect

    response_hash_single = nil
    5.times do |i|
      begin
        response_hash_single = tw.queue
      rescue => ex
        puts ex.message
      end
    end

    puts 'response_hash=' + response_hash_single.inspect
    puts 'task_id=' + tw.task_id
    10.times do |i|
      puts "status #{i}: " + tw.status.inspect
      break if tw.status["status"] == "complete"
      sleep 2
    end

    assert tw.status["status"] == "complete"

  end

  def test_global_attributes
    worker = TestWorker3.new
    worker.run_local

    puts 'worker=' + worker.inspect

    assert_equal "sa", worker.db_user
    assert_equal "pass", worker.db_pass
    assert_equal 123, worker.x

  end


  def test_data_passing
    cool = CoolWorker.new
    cool.array_of_models = [CoolModel.new(:name=>"name1"), CoolModel.new(:name=>"name2")]
    cool.queue
    status = wait_for_task(cool)
    assert status["status"] == "complete"
    log = SimpleWorker.service.log(cool.task_id)
    puts 'log=' + log.inspect
    assert log.length > 10

  end

  def test_exceptions
    worker = TestWorker.new
    worker.queue
    status = wait_for_task(worker)
    assert status["status"] == "error"
    assert status["msg"].present?
  end

  def test_active_record
    dbw = DbWorker.new
    dbw.run_local
    assert !dbw.ob.nil?
    assert !dbw.ob.id.nil?

    dbw.queue
      # would be interesting if the object could update itself on complete. Like it would retrieve new values from
      # finished job when calling status or something.

    status = wait_for_task(dbw)
    assert status["status"] == "complete"


  end


  def test_require_relative_merge


  end
end

