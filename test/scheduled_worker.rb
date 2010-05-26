begin
    require File.join(File.dirname(__FILE__), '../lib/simple_worker')
rescue Exception
    require 'simple_worker'
end


class ScheduledWorker < SimpleWorker::Base

    def scheduled_run(data=nil)
        log "This is scheduled yes it is"
        log data.inspect
    end

end
