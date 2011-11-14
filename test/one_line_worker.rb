# bump......
class OneLineWorker < SimpleWorker::Base

  #merge_gem 'webrobots'

  attr_accessor :x

  def run
    puts "hello world! #{x}"
  end
end
