require_relative 'test_base'
require_relative 'one_line_worker'
require 'active_support/core_ext'

class IronWorkerTests < TestBase

  def test_scheduler
    worker = OneLineWorker.new

    start_time = Time.now
    worker.schedule(:start_at=>30.seconds.from_now)
    status = wait_for_task(worker)
    assert status["status"] == "complete"
    end_time = Time.now
    duration = (end_time-start_time)
    puts "duration=#{duration}"
    assert duration > 30

    worker.schedule(:start_at=>1.seconds.from_now, :run_every=>5, :end_at=>60.seconds.from_now)
    status = wait_for_task(worker)
    assert status["status"] == "complete"
    puts "run_count=#{status["run_count"]}"
    assert status["run_count"] > 5
    assert status["run_count"] < 20

    worker.schedule(:start_at => 2.seconds.since, :run_every => 5, :run_times => 5)
    status = wait_for_task(worker)
    assert status["status"] == "complete"
    puts "run_count=#{status["run_count"]}"
    assert status["run_count"] == 5
  end

  def test_schedule_cancel
    worker = OneLineWorker.new

    start_time = Time.now
    worker.schedule(start_at: 30.seconds.from_now)
    IronWorker.service.cancel_schedule(worker.schedule_id)
    assert_equal worker.status['status'], 'cancelled'
  end

end

