require 'simple_worker'

class ScheduledWorker < SimpleWorker::Base

    def scheduled_run(data=nil)
        log "This is scheduled yes it is"
        log data.inspect
    end

end
