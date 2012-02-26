begin
    require File.join(File.dirname(__FILE__), '../lib/iron_worker')
rescue Exception
    require 'iron_worker'
end


class ScheduledWorker < IronWorker::Base

    def run
        log "This is scheduled yes it is"
        log data.inspect
    end

end
