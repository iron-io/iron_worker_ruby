require_relative 'test_base'
require_relative 'one_line_worker'
require_relative 'merging_worker'
require_relative 'progress_worker'
require 'concur'
#require_relative 'prawn_worker'

class BatchRun < TestBase

  def test_worker

    SimpleWorker.logger.level = Logger::INFO

    response_hash = nil
    test_runner = nil
    jobs = []

    worker = OneLineWorker3.new
    worker.upload

    executor = Concur::Executor.new_thread_pool_executor(50)
    1000.times do |i|
      jobs << executor.execute do
        begin
          worker = OneLineWorker3.new
          puts "queueing #{i}"
          response_hash = worker.queue(:priority=>(@config[:priority] || 0))
          puts "response_hash #{i} = " + response_hash.inspect
          assert response_hash["msg"]
          assert response_hash["status_code"]
          assert response_hash["tasks"]
          assert response_hash["status_code"] == 200
          assert response_hash["tasks"][0]["id"]
          worker
        rescue => ex
          puts "ERROR! #{ex.class.name}: #{ex.message} -- #{ex.backtrace.inspect}"
          raise ex
        end

      end
    end

    sleep 10

    completed_count = 0
    errored_queuing_count = 0
    error_count = 0
    while jobs.size > 0
      jobs.each_with_index do |f, i|
#    p f
        begin
          t = f.get
#      p t
          puts i.to_s + ' task_id=' + t.task_id.to_s
          status_response = t.status # worker.status(t["task_id"])
          puts 'status ' + status_response["status"] + ' for ' + status_response.inspect
          if status_response["status"] == "complete" || status_response["status"] == "error"
            if status_response["status"] == "error"
              puts t.get_log
            end

            jobs.delete(f)
            completed_count += 1
            puts "#{completed_count} completed so far. #{jobs.size} left..."
            if status_response["status"] == "error"
              error_count += 1
            end
          end
        rescue => ex
          puts 'error! ' + ex.class.name + ' -> ' + ex.message.to_s
          puts ex.backtrace
          errored_queuing_count += 1
          jobs.delete(f)
        end
      end
      puts 'sleep'
      sleep 2
      puts 'done sleeping'
    end

    puts 'Total completed=' + completed_count.to_s
    puts 'Total errored while queuing=' + errored_queuing_count.to_s
    puts 'Total errored while running=' + error_count.to_s

    executor.shutdown


    #tasks = []
    #1000.times do |i|
    #  puts "#{i}"
    #  worker = ProgressWorker.new
    #  #worker = OneLineWorker.new
    #  #    worker = MergingWorker.new
    #  #worker = PrawnWorker.new
    #  worker.queue
    #  tasks << worker
    #end
    #
    #tasks.each_with_index do |task, i|
    #  puts "#{i}"
    #  status = task.wait_until_complete
    #  p status
    #  puts "\n\n\nLOG START:"
    #  puts task.get_log
    #  puts "LOG END\n\n\n"
    #  assert status["status"] == "complete", "Status was not complete, it was #{status["status"]}"
    #end
    SimpleWorker.logger.level = Logger::DEBUG

  end

end

