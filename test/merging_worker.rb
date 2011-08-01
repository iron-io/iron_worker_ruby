# bump.......

class MergingWorker < SimpleWorker::Base

  merge_gem 'mini_fb'
  merge_folder './models'

  merge 'cool_model'
  unmerge 'models/model_2.rb'
  merge_worker 'second_worker.rb', 'SecondWorker'

  attr_accessor :s3_key, :times, :x

  def run
    raise "Model2 was found!" if defined?(Model2)
    m1 = Model1.new
    log "I made a new model1"
    m1.say_hello

    second_workers = []
    now = Time.now
    10.times do |i|
      second_worker = SecondWorker.new
      second_worker.start_time = now
      second_worker.num = i
      second_worker.queue
      second_workers << second_worker
    end

    second_workers.each do |sw|
      puts sw.to_s
      puts sw.status["status"].to_s
      p sw.wait_until_complete.inspect
    end

  end


end
