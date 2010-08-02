begin
    require File.join(File.dirname(__FILE__), '../lib/simple_worker')
rescue Exception => ex
    puts ex.message
    require 'simple_worker'
end
require 'test_worker_2'

class TestWorker3 < TestWorker2


    attr_accessor :s3_key, :times

    def run()

    end

end

