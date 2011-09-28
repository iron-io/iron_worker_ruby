# Bump....
class TestWorker < SimpleWorker::Base

    attr_accessor :s3_key, :times

    def run
        log 'running the test worker for moi '.upcase
        log 's3_key instance_variable = ' + self.s3_key.to_s

        @times.times do |i|
            log 'running at ' + i.to_s
            sleep 1
            set_progress(:percent=> (i / @times * 100))
        end
    end

    def set_complete(params=nil)
        log 'SET COMPLETE YAY!' + params[:task_set_id]
    end


end

