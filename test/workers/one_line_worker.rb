# bump......
class OneLineWorker < IronWorker::Base

  merge_gem 'iron_mq'
  merge_gem 'rest-client', :require=>'rest_client'

  attr_accessor :x

  def run
    puts "hello world! #{x}"
    mq = IronMQ::Client

    puts 'getting url'
    r = RestClient.get 'http://example.com/resource'
    p r.body
  end
end
