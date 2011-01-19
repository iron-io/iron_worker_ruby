require 'test/unit'
begin
  require File.join(File.dirname(__FILE__), '../lib/simple_worker')
rescue Exception => ex
  puts ex.message
  require 'simple_worker'
end
require_relative "test_worker"
require_relative "test_worker_2"


class SimpleWorkerTests < Test::Unit::TestCase

  def test_no_conf
    # Add something to queue, get task ID back
    tw        = TestWorker.new
    tw.s3_key = "active style runner"
    tw.times  = 3

    tw.run_local

  end

end

