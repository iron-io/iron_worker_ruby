require_relative 'test_base'
require_relative 'workers/one_line_worker'
require 'active_support/core_ext'

class IronWorkerTests < TestBase

  def test_scheduler
    worker = OneLineWorker.new

    start_time = Time.now
    worker.schedule(:start_at=>30.seconds.from_now)
    status = worker.wait_until_complete
    assert status["status"] == "complete"
    end_time = Time.now
    duration = (end_time-start_time)
    puts "duration=#{duration}"
    assert duration > 30

    worker.schedule(:start_at=>1.seconds.from_now, :run_every=>5, :end_at=>60.seconds.from_now)
    status = worker.wait_until_complete
    assert status["status"] == "complete"
    puts "run_count=#{status["run_count"]}"
    assert status["run_count"] > 5
    assert status["run_count"] < 20

    worker.schedule(:start_at => 2.seconds.since, :run_every => 5, :run_times => 5)
    status = worker.wait_until_complete
    assert status["status"] == "complete"
    puts "run_count=#{status["run_count"]}"
    assert status["run_count"] == 5
  end

  def test_schedule_cancel
    puts 'test_schedule_cancel'
    worker = OneLineWorker.new
    worker.schedule(start_at: 30.seconds.from_now)
    p worker
    IronWorker.service.cancel_schedule(worker.schedule_id)
    assert_equal worker.status['status'], 'cancelled'
  end

  def test_schedules_paging
    puts 'test_schedule_cancel'
    1.times do |i|
      worker = OneLineWorker.new
      worker.schedule(start_at: 30.seconds.from_now)
      p worker
    end
    sleep 1
    page = 0
    while true
      puts "page #{page}"
      schedules = IronWorker.service.schedules(:page=>page)['schedules']
      page += 1
      puts 'schedules=' + schedules.inspect
      puts 'schedules.size=' + schedules.size.to_s
      if schedules.size == 0
        return
      end
      schedules.each do |s|
        puts "schedule: #{s['id']} #{s['status']}"
        if s['status'] != 'scheduled'
          next
        end
        puts 'SCHEDULED!! Cancelling...'
      end
    end
  end

end

