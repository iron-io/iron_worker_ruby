# bump......
class RailsWorker < SimpleWorker::Base

  merge_worker 'rails_worker2', 'RailsWorker2'

  def run
    puts "hello rails! env=#{Rails.env}"
    worker2 = RailsWorker2.new
    worker2.queue

    worker2.wait_until_complete
    log = worker2.get_log
    puts "START WORKER2 LOG:"
    puts log
    puts "END WORKER2 LOG"


  end
end
