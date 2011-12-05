# Bump..................
class TestWorker2 < IronWorker::Base

    merge File.join(File.dirname(__FILE__), 'models', 'model_1.rb')
    unmerge 'models/model_2.rb'
    merge_worker File.join(File.dirname(__FILE__), 'second_worker.rb'), 'SecondWorker'
    #merge_worker 'second_worker.rb', 'SecondWorker'

    attr_accessor :s3_key, :times, :x


    def who_am_i2?
        return self.class.name
    end

    def run
        log 'running the runner for leroy '.upcase + ' with data: '

        log 's3_key instance_variable = ' + self.s3_key
        times.times do |i|
            log 'running at ' + i.to_s
            sleep 0.3
            #set_progress(:percent=> (i / times * 100))
        end
        m1 = Model1.new
        log "I made a new model1"
        m1.say_hello

        second_workers = []
        now = Time.now
        #10.times do |i|
        #    second_worker = SecondWorker.new
        #    second_worker.start_time = now
        #    second_worker.num = i
        #    second_worker.queue
        #    second_workers << second_worker
        #end
        #
        #10.times do |i|
        #    second_workers.each do |sw|
        #        puts sw.to_s
        #        puts sw.status["status"].to_s
        #    end
        #end
    end

    def set_complete(params=nil)
        log 'SET COMPLETE YAY!' + params[:task_set_id]
    end

end
