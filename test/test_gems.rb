require_relative 'test_base'
require_relative 'awesome_job'


class TestGems < TestBase

  def test_dropbox_gem

    worker = AwesomeJob.new
    worker.queue

    wait_for_task(worker)

    puts 'log=' + worker.get_log

  end

end
