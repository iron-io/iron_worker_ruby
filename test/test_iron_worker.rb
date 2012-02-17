require_relative 'test_base'
require_relative 'cool_worker'
require_relative 'cool_model'
require_relative 'gem_dependency_worker'
require_relative 'fail_worker'
require_relative 'progress_worker'
require_relative 'one_line_worker'
require_relative 'workers/big_gems_worker'
require_relative 'workers/tmp_dir_worker'
require_relative 'workers/webhook_worker'

class IronWorkerTests < TestBase

  # todo: test both gems
    #def test_rest_client
    #  Uber.gem = :rest_client
    #
    #  worker = OneLineWorker.new
    #  worker.queue
    #
    #  IronWorker.service.host = "http://www.wlajdfljalsjfklsldf.com/"
    #  IronWorker.service.reset_base_url
    #
    #  status = worker.wait_until_complete
    #  p status
    #  p status["error_class"]
    #  p status["msg"]
    #  puts "\n\n\nLOG START:"
    #  log = worker.get_log
    #  puts log
    #  puts "LOG END\n\n\n"
    #  assert status["status"] == "complete", "Status was not complete, it was #{status["status"]}"
    #  Uber.gem = :typhoeus
    #end


  def test_old_gem_error_message
    assert_raise do
      IronWorker.config.access_key = "abc"
    end
    assert_raise do
      assert_raise IronWorker.config.secret_key = "abc"
    end
  end

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
    log = IronWorker.service.log(cool.task_id)
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
    puts 'STATUS: ' + status.inspect
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

  def test_tmpdir
    worker = TmpDirWorker.new
    worker.queue
    status = wait_for_task(worker)
    assert status["status"] == "complete"
    log = worker.get_log
    assert log.include?("TMPDIR"), "TMPDIR is not set"
    assert log.include?("tmp"), "There is no tmp dir in user dir"
  end

  def test_progress
    worker = ProgressWorker.new
    worker.s3_key = "YOOOOO"
    worker.queue

    status = worker.wait_until_complete
    p status
    p status["error_class"]
    p status["msg"]
    puts "\n\n\nLOG START:"
    log = worker.get_log
    puts log
    puts "LOG END\n\n\n"
    puts "Status:"
    puts status
    assert status["status"] == "complete", "Status was not complete, it was #{status["status"]}"
    assert log.include?(worker.s3_key)
    #assert status["percent"]
    #assert status["percent"] > 0
  end

  def test_big_gems_worker

    #raise "BigGemWorker DOESN'T WORK, remove this raise when fixed."

    worker = BigGemsWorker.new
    worker.queue

    status = worker.wait_until_complete
    p status
    p status["error_class"]
    p status["msg"]
    puts "\n\n\nLOG START:"
    log = worker.get_log
    puts log
    puts "LOG END\n\n\n"
    assert status["status"] == "complete", "Status was not complete, it was #{status["status"]}"
    assert log.include?("hello")
  end

  def test_webhook
    worker = WebhookWorker.new
    worker.upload

    code_name = worker.class.name
    payload = "webhooked!"

    # Now we hit the webhook
    @uber_client = Rest::Client.new
    url = "https://worker-aws-us-east-1.iron.io/2/projects/#{@project_id}/tasks/webhook?code_name=#{code_name}&oauth=#{@token}"
    resp = @uber_client.post(url, {:body=>payload})
    p resp
    body = JSON.parse(resp.body)
    p body

    @task_id = body["id"]

    resp = @uber_client.get("https://worker-aws-us-east-1.iron.io/2/projects/#{@project_id}/tasks/#{@task_id}?oauth=#{@token}")
    p resp

    status = IronWorker.service.wait_until_complete(@task_id)
    p status
    assert status["status"]
    puts status["msg"]

    puts "LOG:"
    log = IronWorker.service.get_log(@task_id)
    puts log
    assert log.include?(payload)

  end

end

