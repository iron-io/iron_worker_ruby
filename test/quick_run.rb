require_relative 'test_base'
require_relative 'workers/one_line_worker'
require_relative 'workers/progress_worker'
require_relative 'workers/fail_worker'

class QuickRun < TestBase

  def test_worker
    tasks = []
    100.times do |i|
      worker = OneLineWorker.new
      worker.x = 10
      worker.queue
      tasks << worker
    end

    tasks.each do |worker|
      status = worker.wait_until_complete
      p status
      puts "error_class: #{status["error_class"]}"
      puts "msg: #{status["msg"]}"
      puts "percent: #{status["percent"]}"
      puts "\n\n\nLOG START:"
      log = worker.get_log
      puts log
      puts "LOG END\n\n\n"
      assert status["status"] == "complete", "Status was not complete, it was #{status["status"]}"
      assert log.include?("hello")
    end
  end

end

