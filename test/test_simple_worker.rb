require_relative 'test_base'

class SimpleWorkerTests < TestBase


  def test_new_worker_style
    # Add something to queue, get task ID back
    tw        = TestWorker2.new
    tw.s3_key = "active style runner"
    tw.times  = 3
    tw.x      = true

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

    50.times do |i|
      begin
        response_hash_single = tw.queue
      rescue => ex
          puts ex.message
      end
    end

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

  def test_global_attributes
    worker = TestWorker3.new
    worker.run_local

    puts 'worker=' + worker.inspect

    assert_equal "sa", worker.db_user
    assert_equal "pass", worker.db_pass
    assert_equal 123, worker.x

  end

  def test_require_relative_merge


  end
end

