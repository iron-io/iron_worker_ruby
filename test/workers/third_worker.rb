# bump.............
class ThirdWorker < IronWorker::Base
  def run
    puts 'hi there, i am number 3'
  end
end