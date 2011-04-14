require_relative 'test_base'
require_relative 'gem_dependency_worker'

class QuickRun < TestBase

  def test_worker
    worker = GemDependencyWorker.new
    worker.queue
    status = worker.wait_until_complete
    p status
    assert status["status"] == "complete", "Status was not complete, it was #{status["status"]}"
    puts worker.get_log
  end

end