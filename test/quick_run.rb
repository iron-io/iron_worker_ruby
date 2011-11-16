require_relative 'test_base'
require_relative 'one_line_worker'
require_relative 'workers/qb_worker'

class QuickRun < TestBase

  def test_worker
    10.times do |i|
      worker = QbWorker.new
      worker.x = 10
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
  end

end

