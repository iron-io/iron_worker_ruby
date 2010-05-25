begin
    require File.join(File.dirname(__FILE__), '../lib/simple_worker')
rescue Exception
    require 'simple_worker'
end

# Bump for new checksum.
class TestWorker2 < SimpleWorker::Base

    merge "models/model_1.rb"

    attr_accessor :s3_key, :times, :x


    def who_am_i2?
        return self.class.name
    end

    def run(data=nil)
        log 'running the runner for leroy '.upcase + ' with data: ' + data.inspect

        log 's3_key instance_variable = ' + self.s3_key
        times.times do |i|
            log 'running at ' + i.to_s
            sleep 1
            set_progress(:percent=> (i / times * 100))
        end
        m1 = Model1.new
        log "I made a new model1"
        m1.say_hello
    end

    def set_complete(params=nil)
        log 'SET COMPLETE YAY!' + params[:task_set_id]
    end

end

