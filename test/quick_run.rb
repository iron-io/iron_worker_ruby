require_relative 'test_base'
require_relative 'workers/one_line_worker'
require_relative 'workers/progress_worker'
require_relative 'workers/fail_worker'

class QuickRun < TestBase

  def test_worker
    tasks = []
    50.times do |i|
      puts "Queuing #{i}"
      worker = OneLineWorker.new
      worker.x = i
      worker.queue
      tasks << worker
    end

    tasks.each_with_index do |worker, i|
      puts "Waiting for #{i}"
      status = worker.wait_until_complete
      puts "#{i} is complete."
      p status
      puts "error_class: #{status["error_class"]}"
      puts "msg: #{status["msg"]}"
      puts "percent: #{status["percent"]}"
      sleep 1
      puts "\n\n\nLOG START:"
      log = worker.get_log
      puts log
      puts "LOG END\n\n\n"
      assert status["status"] == "complete", "Status was not complete, it was #{status["status"]}"
      assert log.include?("hello")
    end
  end

end

