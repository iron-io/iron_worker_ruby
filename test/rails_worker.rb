# bump......
class RailsWorker < SimpleWorker::Base

  merge_worker 'rails_worker2', 'RailsWorker2'

  def run
    puts "hello rails! env=#{Rails.env}"
    worker2 = RailsWorker2.new
    worker2.queue

  end
end
