begin
    require File.join(File.dirname(__FILE__), '../../lib/simple_worker')
rescue Exception => ex
    puts 'ERROR!!! ' + ex.message
#    require 'simple_worker'
end


class Model1
    attr_accessor :heidi, :ho

    include SimpleWorker::UsedInWorker

    def say_hello
        log "Hi there sir"
    end

    # testk laksdfj klasj df
    def test
        log 'test'
    end
end
