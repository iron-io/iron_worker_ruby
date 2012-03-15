# Bump...............
class TestWorker < IronWorker::Base

  attr_accessor :s3_key, :times

  def initialize
    @times = 1
  end

  def run
    log 'running the test worker for moi '.upcase
    log 's3_key instance_variable = ' + self.s3_key.to_s

    @times.times do |i|
      puts 'running at ' + i.to_s
      sleep 1
      set_progress(:percent => (1.0 * i / @times * 100).round, :msg => "getting there...")
    end
  end

end

