require 'rake/dsl_definition' # temporary I think?
require 'rake/testtask'
require 'jeweler2'

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
  #gemspec.add_dependency 'typhoeus'
  gemspec.required_ruby_version = '>= 1.9'
end
Jeweler::GemcutterTasks.new

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/test*.rb']
  t.verbose = true
end


