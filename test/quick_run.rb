require_relative 'test_base'
require_relative 'test_worker_4'

class QuickRun < TestBase

  def test_worker
    #worker = MergingWorker.new
    worker = TestWorker4.new
    worker.queue

    status = worker.wait_until_complete
    p status
    puts "\n\n\nLOG START:"
    puts worker.get_log
    puts "LOG END\n\n\n"
    assert status["status"] == "complete", "Status was not complete, it was #{status["status"]}"
  end

end

