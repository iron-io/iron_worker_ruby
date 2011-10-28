# bump......
class OneLineWorker2 < SimpleWorker::Base

  def run
    puts "hello world!"
  end
end
