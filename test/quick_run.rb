require_relative 'test_base'
require_relative 'merging_worker'

class QuickRun < TestBase

  def test_worker
    worker = MergingWorker.new
    worker.queue
    status = worker.wait_until_complete
    p status
    puts worker.get_log
    assert status["status"] == "complete", "Status was not complete, it was #{status["status"]}"
  end

end