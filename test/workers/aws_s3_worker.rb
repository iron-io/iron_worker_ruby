# bump..
class AwsS3Worker < IronWorker::Base

  merge_gem "aws-s3", :require => 'aws/s3'

  def run
    puts "i'm running"
  end

end
