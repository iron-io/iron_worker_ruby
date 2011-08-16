

class TestWorker4 < SimpleWorker::Base

  merge 'resources/something.yml'

  attr_accessor :x

  def run()
    puts 'TestWorker4.run'

    #something = YAML.load('resources/something.yml')
    #p something

  end

end

