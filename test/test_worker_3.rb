begin
    require File.join(File.dirname(__FILE__), '../lib/simple_worker')
rescue Exception => ex
    puts ex.message
    require 'simple_worker'
end
require_relative 'test_worker_2'

class TestWorker3 < TestWorker2


    attr_accessor :x, :db_user, :db_pass

    def run()
        puts 'TestWorker3.run'
        @x = 123
    end

end

