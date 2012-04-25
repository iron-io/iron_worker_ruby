# bump......
class BigDataWorker < IronWorker::Base

  attr_accessor :x

  def run
    puts "hello world! #{x}"
    sleep_for = 30
    puts "sleeping for #{sleep_for} seconds..."
    sleep sleep_for
    puts "Done sleeping and done working."

  end
end

