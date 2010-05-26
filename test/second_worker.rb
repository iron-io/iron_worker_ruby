begin
    require File.join(File.dirname(__FILE__), '../lib/simple_worker')
rescue Exception => ex
    puts ex.message
    require 'simple_worker'
end

class SecondWorker < SimpleWorker::Base
    attr_accessor :start_time, :num

    # change

    def run
        log self.to_s
    end

    def to_s
        "I am Second Worker #{num}. I was started at #{start_time}"
    end
end
