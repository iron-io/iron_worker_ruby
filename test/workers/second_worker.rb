# bump..
class SecondWorker < IronWorker::Base
    attr_accessor :start_time, :num

    merge_worker 'third_worker.rb', 'ThirdWorker'

    # change

    def run
        log self.to_s
    end

    def to_s
        "I am Second Worker #{num}. I was started at #{start_time}"
    end
end
