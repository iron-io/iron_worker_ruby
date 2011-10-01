#bump...........,...
require_relative 'test_worker_2'

class TestWorker3 < TestWorker2


  attr_accessor :x, :db_user, :db_pass

  def run()
    puts 'TestWorker3.run'
    @x = 123
  end

end

