begin
    require File.join(File.dirname(__FILE__), '../lib/simple_worker')
rescue Exception => ex
    puts ex.message
    require 'simple_worker'
end
# Bump for new checksum.
class TestWorker < SimpleWorker::Base

    attr_accessor :s3_key, :times

    def run(data=nil)
        log 'running the runner for leroy '.upcase + ' with data: ' + data.inspect

        log 's3_key instance_variable = ' + self.s3_key.to_s

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

