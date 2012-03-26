require_relative 'test_base'
require_relative 'workers/awesome_job'
require_relative 'workers/aws_s3_worker'

class TestGems < TestBase

  def test_dropbox_gem

    worker = AwesomeJob.new
    worker.queue

    worker.wait_until_complete

    puts 'log=' + worker.get_log

  end

  def test_aws_s3_gem

    worker = AwsS3Worker.new
    puts 'run_local'
    worker.run_local
    worker.queue

    worker.wait_until_complete

    puts 'log=' + worker.get_log

  end

end
