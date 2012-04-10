# bump......
class RailsWorker < IronWorker::Base

  merge_worker 'rails_worker2', 'RailsWorker2'

  def run
    puts "hello rails! env=#{Rails.env}"
    worker2 = nil
    10.times do |i|
      worker2 = RailsWorker2.new
      worker2.x = "yz #{i}"
      worker2.queue(:priority=>2)
    end

    worker2.wait_until_complete
    sleep 2
    log = worker2.get_log
    puts "START WORKER2 LOG:"
    puts log
    puts "END WORKER2 LOG"


  end
end
