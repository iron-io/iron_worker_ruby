require_relative 'test_base'
require_relative 'workers/broken_load_worker'
require_relative 'one_line_worker'
require_relative 'merging_worker'


class QuickRun < TestBase

  def test_worker
    worker = BrokenLoadWorker.new
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
    assert log.include?(worker.s3_key)
  end

end

