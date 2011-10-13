require_relative 'test_base'
require_relative 'db_worker'
require_relative 'db_model'
class SimpleWorkerTests < TestBase

  def setup
    super
    SimpleWorker.config.database = @config['database']
  end

  def test_active_record
    dbw = DbWorker.new
    dbw.run_local
    assert !dbw.ob.nil?
    assert !dbw.ob.id.nil?

    dbw.queue
    # would be interesting if the object could update itself on complete. Like it would retrieve new values from
    # finished job when calling status or something.

    status = wait_for_task(dbw)
    puts 'status: ' + status.inspect
    puts "\n\n\nLOG START:"
    puts dbw.get_log
    puts "LOG END\n\n\n"
    assert status["status"] == "complete"


  end

end
