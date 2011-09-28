class ThirdWorker < SimpleWorker::Base
  def run
    puts 'hi there, i am number 3'
  end
end