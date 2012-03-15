class LocalVsRemoteWorker < IronWorker::Base

  attr_accessor :x

  def run
    puts "is_local? #{is_local?}"
    puts "is_remote? #{is_remote?}"
  end
end
