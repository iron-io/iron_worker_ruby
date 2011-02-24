require 'mysql2'

class DbWorker < SimpleWorker::Base
  attr_accessor :array_of_models
  merge 'trace_object'

  def run
    to = TraceObject.find(:first)
    log to.inspect
    @object = to
  end

  def ob
    @object
  end


end
