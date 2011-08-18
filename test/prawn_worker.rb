# bump.............
require 'prawn'

class PrawnWorker < SimpleWorker::Base

  merge 'resources/something.yml'
  merge_gem 'prawn', :include_dirs=>['data']
  merge_gem "pdf-reader"

  attr_accessor :x

  def run()
    puts 'TestWorker4.run'

    #something = YAML.load('resources/something.yml')
    #p something

    Prawn::Document.generate("hello.pdf") do
      text "Hello World!"
    end

    # now list files to see that it was created
    puts "files in user_dir"
    Dir.glob("*").each do |f|
      puts f
    end

    raise PDF::Reader::UnsupportedFeatureError


  end

end

