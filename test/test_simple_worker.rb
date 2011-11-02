require_relative 'test_base'
require_relative 'cool_worker'
require_relative 'cool_model'
require_relative 'gem_dependency_worker'
require_relative 'fail_worker'

class SimpleWorkerTests < TestBase

  def test_gem_merging
    worker = GemDependencyWorker.new
    worker.queue
    status = worker.wait_until_complete
    p status
    puts_log(worker)
    assert status["status"] == "complete", "Status was not complete, it was #{status["status"]}"
  end

  def test_new_worker_style
    # Add something to queue, get task ID back
    tw = TestWorker2.new
    tw.s3_key = "active style runner"
    tw.times = 3
    tw.x = true

    # queue up a task
    puts 'queuing ' + tw.inspect

    response_hash = nil
    5.times do |i|
      response_hash = tw.queue
    end

    puts 'response_hash=' + response_hash.inspect
    puts 'task_id=' + tw.task_id

    assert response_hash["msg"]
    assert response_hash["status_code"]
    assert response_hash["tasks"]
    assert response_hash["status_code"] == 200
    assert response_hash["tasks"][0]["id"].length == 24, "length is #{response_hash["tasks"][0]["id"].length}"
    assert response_hash["tasks"][0]["id"] == tw.task_id

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
    worker = FailWorker.new
    worker.queue
    status = wait_for_task(worker)
    assert status["status"] == "error"
    assert status["msg"].present?
  end



end

