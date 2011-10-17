require_relative 'test_base'
require_relative 'one_line_worker'
require_relative 'merging_worker'
require_relative 'progress_worker'
#require_relative 'prawn_worker'

class QuickRun < TestBase

  def test_scheduler
    worker = TestWorker.new
    worker.schedule(:start_at=>10.seconds.from_now)
    status = wait_for_task(worker)
    assert status["status"] == "error"
    assert status["msg"].present?
  end

end

