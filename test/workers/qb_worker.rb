class QbWorker < IronWorker::Base

  merge_worker 'running_back_worker', 'RunningBackWorker'

  attr_accessor :x

  def run
    IronWorker.logger.level = Logger::DEBUG
    puts "Qb passing off to running backs..."
    x ||= 10
    x.times do |i|
      worker = RunningBackWorker.new
      worker.i = i
      worker.queue(:priority=>0)
    end
  end
end
