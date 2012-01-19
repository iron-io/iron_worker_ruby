require "rubygems"
require "bundler/setup"

require 'rake/dsl_definition' # temporary I think?
require 'rake/testtask'
require 'jeweler2'

Jeweler::Tasks.new do |gemspec|
  gemspec.name = "iron_worker"
  gemspec.summary = "The official IronWorker gem for IronWorker by Iron.io. http://www.iron.io"
  gemspec.description = "The official IronWorker gem for IronWorker by Iron.io. http://www.iron.io"
  gemspec.email = "travis@iron.io"
  gemspec.homepage = "http://www.iron.io"
  gemspec.authors = ["Travis Reeder"]
  gemspec.files = FileList['VERSION.yml','init.rb', 'lib/**/*.rb', 'rails/**/*.rb']
  gemspec.add_dependency 'zip'
  gemspec.add_dependency 'rest-client'
  gemspec.add_dependency 'rest'
  gemspec.add_dependency 'bundler'
  #gemspec.add_dependency 'typhoeus'
  gemspec.required_ruby_version = '>= 1.9'
end
Jeweler::GemcutterTasks.new

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/test*.rb']
  t.verbose = true
end


