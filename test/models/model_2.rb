

class Model2
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
