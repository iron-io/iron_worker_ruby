require_relative 'test_base'
require 'active_record'
require_relative 'workers/cool_worker'
require_relative 'models/cool_model'
require_relative 'models/db_model'
require_relative 'workers/prawn_worker'

class IronWorkerTests < TestBase

  def test_merge_worker
    tw = TestWorker2.new
    tw.s3_key = "active style runner"
    tw.times = 3
    tw.x = true

    response_hash_single = nil
    5.times do |i|
      begin
        response_hash_single = tw.queue
      rescue => ex
        puts ex.message
        raise ex
      end
    end

    puts 'response_hash=' + response_hash_single.inspect
    puts 'task_id=' + tw.task_id
    status = tw.wait_until_complete
    puts 'log=' + tw.get_log
    assert tw.status["status"] == "complete"
  end
  
  def test_include_dirs
    omit
    worker = PrawnWorker.new
    worker.queue

    status = worker.wait_until_complete
    p status
    puts "\n\n\nLOG START:"
    l = worker.get_log
    puts l
    puts "LOG END\n\n\n"
    assert status["status"] == "complete", "Status was not complete, it was #{status["status"]}"
    assert l.include?("hello.pdf")
  end

  def test_merge_mailer

  end

end
