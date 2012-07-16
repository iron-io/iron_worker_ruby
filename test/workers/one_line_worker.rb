# bump......
class OneLineWorker < IronWorker::Base


  attr_accessor :x

  def run
    puts "hello world! #{x}"
  end
end
