require 'simple_worker'

class TestRunner

    include SimpleWorker::Worker

    def run(data=nil)
        puts 'running the runner for leroy '.upcase + ' with data: ' + data.inspect
        @times = data["times"].to_i
        @times.times do |i|
            puts 'running at ' + i.to_s
            sleep 1
            set_progress(:percent=> (i / @times * 100))
        end
    end

    def set_complete(params=nil)
        puts 'SET COMPLETE YAY!' + params[:task_set_id]
    end

    def progress
        if @count
            return @count / @times
        end
        return 0.0
    end



end

