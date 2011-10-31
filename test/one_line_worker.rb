# bump......
class OneLineWorker3 < SimpleWorker::Base

  def run
    puts "hello world!"
  end
end
