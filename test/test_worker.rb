require 'simple_worker'

# Bump for new checksum.
class TestWorker < SimpleWorker::Base

    def run(data=nil)
        log 'running the runner for leroy '.upcase + ' with data: ' + data.inspect
        @times = data["times"].to_i
        @times.times do |i|
            log 'running at ' + i.to_s
            sleep 1
            set_progress(:percent=> (i / @times * 100))
        end
    end

    def set_complete(params=nil)
        log 'SET COMPLETE YAY!' + params[:task_set_id]
    end

    def progress
        if @count
            return @count / @times
        end
        return 0.0
    end

end

