

class Model1
    attr_accessor :heidi, :ho

    include IronWorker::UsedInWorker

    def say_hello
        log "Hi there sir"
    end

    # testk laksdfj klasj df
    def test
        log 'test'
    end
end
