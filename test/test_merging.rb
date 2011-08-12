require 'active_record'
require_relative 'test_base'
require_relative 'cool_worker'
require_relative 'cool_model'
require_relative 'trace_object'
require_relative 'db_worker'
require_relative 'gem_dependency_worker'

class SimpleWorkerTests < TestBase

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
      end
    end

    puts 'response_hash=' + response_hash_single.inspect
    puts 'task_id=' + tw.task_id
    status = tw.wait_until_complete
    puts 'log=' + tw.get_log
    assert tw.status["status"] == "complete"
  end

end
