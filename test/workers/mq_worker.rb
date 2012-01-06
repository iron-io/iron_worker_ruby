# bump......
class MqWorker < IronWorker::Base

  merge_gem 'iron_mq'

  attr_accessor :config

  def run
    rest = Rest::Client.new
    resp = rest.get 'http://169.254.169.254/2009-04-04/meta-data/instance-id'
    puts 'instance_id=' + resp.body
    @mq = IronMQ::Client.new(:token=>config['token'], :project_id=>config['project_id'], :queue_name=>'mq_worker')
    puts 'putting message on queue'
    resp = @mq.messages.post("Hello world!")
    puts "posted #{resp.id}"
    puts 'getting message from queue'
    resp = @mq.messages.get
    puts 'got: ' + resp.body

  end
end
