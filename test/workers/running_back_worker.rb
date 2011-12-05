class RunningBackWorker < IronWorker::Base
  
  attr_accessor :i
  def run
    puts "Running back #{i}"
  end
end
