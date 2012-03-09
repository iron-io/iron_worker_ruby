require_relative 'test_base'
require_relative 'workers/rails_worker'
require 'active_support/core_ext'

module Rails
  def self.env
    "superenviro"
  end
  def self.version
    "3.0.1"
  end
end

class RailsTests < TestBase

  def test_env
    worker = RailsWorker.new
    worker.queue(:priority=>2)

     status = worker.wait_until_complete
    p status
    p status["error_class"]
    p status["msg"]
    puts "\n\n\nLOG START:"
    log = worker.get_log
    puts log
    puts "LOG END\n\n\n"
    assert status["status"] == "complete", "Status was not complete, it was #{status["status"]}"
    assert log.include?("env=" + Rails.env)

  end

end

