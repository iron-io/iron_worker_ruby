# bump.....
class OneLineWorker < SimpleWorker::Base

  def run
    puts "hello world!"
  end
end
