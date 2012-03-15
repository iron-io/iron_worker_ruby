require_relative 'test_base'
require_relative 'workers/one_line_worker'
require 'time'

class IronWorkerTests < TestBase

  def test_scheduler
    worker = OneLineWorker.new

    start_time = Time.now
    worker.schedule(:start_at=>(Time.now + 30).iso8601)
    status = wait_for_task(worker)
    assert status["status"] == "complete"
    end_time = Time.now
    duration = (end_time-start_time)
    puts "duration=#{duration}"
    assert duration > 30

    worker.schedule(:start_at=>Time.now.iso8601, :run_every=>5, :end_at=>(Time.now + 60).iso8601)
    status = wait_for_task(worker)
    assert status["status"] == "complete"
    puts "run_count=#{status["run_count"]}"
    assert status["run_count"] > 5
    assert status["run_count"] < 20

    worker.schedule(:start_at => Time.now.iso8601, :run_every => 5, :run_times => 5)
    status = wait_for_task(worker)
    assert status["status"] == "complete"
    puts "run_count=#{status["run_count"]}"
    assert status["run_count"] == 5
  end


end

