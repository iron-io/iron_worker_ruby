require 'rake/dsl_definition' # temporary I think?

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "simple_worker"
    gemspec.summary = "The official SimpleWorker gem for http://www.simpleworker.com"
    gemspec.description = "The official SimpleWorker gem for http://www.simpleworker.com"
    gemspec.email = "travis@appoxy.com"
    gemspec.homepage = "http://github.com/appoxy/simple_worker"
    gemspec.authors = ["Travis Reeder"]
    gemspec.files = FileList['init.rb', 'lib/**/*.rb', 'rails/**/*.rb']
    gemspec.add_dependency 'zip'
    gemspec.add_dependency 'rest-client'
  end

  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install jeweler -s http://gems.github.com"
end

task :test do
  require './lib/simple_worker'
  ruby 'test/simple_worker_tests.rb'
end

