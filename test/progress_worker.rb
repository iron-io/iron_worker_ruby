# Bump...............
class ProgressWorker < IronWorker::Base

  attr_accessor :s3_key, :times, :x

  def initialize
    @times = 10
  end

  def run
    puts 'hello'
    puts 'running the test worker for moi '.upcase
    puts 's3_key instance_variable = ' + self.s3_key.to_s

    @times.times do |i|
      puts 'loop ' + i.to_s
      sleep 1
      progress = (1.0 * i / @times * 100).round
      puts 'Setting progress to ' + progress.to_s
      set_progress(:percent=> progress, :msg=>"getting there...")
    end
  end


end

