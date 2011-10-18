require_relative 'test_base'
require_relative 'one_line_worker'
require_relative 'merging_worker'
require_relative 'progress_worker'
#require_relative 'prawn_worker'

class QuickRun < TestBase

  def test_worker
    tasks = []
    50.times do |i|
      puts "#{i}"
      worker = ProgressWorker.new
      #worker = OneLineWorker.new
      #    worker = MergingWorker.new
      #worker = PrawnWorker.new
      worker.queue
      tasks << worker
    end

    tasks.each_with_index do |task, i|
      puts "#{i}"
      status = task.wait_until_complete
      p status
      puts "\n\n\nLOG START:"
      puts task.get_log
      puts "LOG END\n\n\n"
      assert status["status"] == "complete", "Status was not complete, it was #{status["status"]}"
    end

  end

end

