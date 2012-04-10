# bump......
class FailWorker < IronWorker::Base

  attr_accessor :x

  def run
    puts "I am about to fail..."
    raise "I wanted to fail and I did!"
  end
end
