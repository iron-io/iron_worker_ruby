require_relative 'test_base'
require_relative 'one_line_worker'
require_relative 'merging_worker'
require_relative 'progress_worker'
#require_relative 'prawn_worker'

class QuickRun < TestBase

  def test_scheduler_quick
    worker = TestWorker.new
    worker.schedule(:start_at=>10.seconds.from_now)
    status = worker.wait_until_complete
    assert status["status"] == "complete"
    assert status["msg"].present?
  end

end

