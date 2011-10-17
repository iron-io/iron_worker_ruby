require_relative 'test_base'
require_relative 'cool_worker'
require_relative 'cool_model'
require_relative 'gem_dependency_worker'

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

    # queue up a task
    puts 'queuing ' + tw.inspect

    response_hash_single = nil
    5.times do |i|
      response_hash_single = tw.queue
    end

    puts 'response_hash=' + response_hash_single.inspect
    puts 'task_id=' + tw.task_id
    status = tw.wait_until_complete

    puts 'LOG=' + tw.get_log
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

  def test_set_progress
    worker = TestWorker.new
    worker.s3_key = "abc"
    worker.times = 10
    worker.queue
    status = worker.wait_until_complete
    p status
    log = worker.get_log
    puts 'log: ' + log
    assert log.include?("running at 5")
    assert status["status"] == "complete"
    assert status["percent"] > 0

  end

  def test_exceptions
    worker = TestWorker.new
    worker.queue
    status = wait_for_task(worker)
    assert status["status"] == "error"
    assert status["msg"].present?
  end

  def test_scheduler
    worker = TestWorker.new
    worker.schedule(:start_at=>10.seconds.from_now)
    status = wait_for_task(worker)
    assert status["status"] == "error"
    assert status["msg"].present?
  end


end

