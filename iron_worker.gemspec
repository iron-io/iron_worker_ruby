# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "iron_worker"
  s.version = "2.3.15"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Travis Reeder"]
  s.date = "2012-07-13"
  s.description = "The official IronWorker gem for IronWorker by Iron.io. http://www.iron.io"
  s.email = "travis@iron.io"
  s.extra_rdoc_files = [
    "LICENSE",
    "README.markdown"
  ]
  s.files = [
    "VERSION.yml",
    "lib/generators/iron_worker/iron_worker_generator.rb",
    "lib/iron_worker.rb",
    "lib/iron_worker/api.rb",
    "lib/iron_worker/base.rb",
    "lib/iron_worker/config.rb",
    "lib/iron_worker/rails2_init.rb",
    "lib/iron_worker/railtie.rb",
    "lib/iron_worker/server/overrides.rb",
    "lib/iron_worker/server/runner.rb",
    "lib/iron_worker/service.rb",
    "lib/iron_worker/used_in_worker.rb",
    "lib/iron_worker/utils.rb",
    "rails/init.rb"
  ]
  s.homepage = "http://www.iron.io"
  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9")
  s.rubygems_version = "1.8.24"
  s.summary = "The official IronWorker gem for IronWorker by Iron.io. http://www.iron.io"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<zip>, [">= 0"])
      s.add_runtime_dependency(%q<rest-client>, [">= 0"])
      s.add_runtime_dependency(%q<rest>, [">= 0"])
      s.add_runtime_dependency(%q<bundler>, [">= 0"])
    else
      s.add_dependency(%q<zip>, [">= 0"])
      s.add_dependency(%q<rest-client>, [">= 0"])
      s.add_dependency(%q<rest>, [">= 0"])
      s.add_dependency(%q<bundler>, [">= 0"])
    end
  else
    s.add_dependency(%q<zip>, [">= 0"])
    s.add_dependency(%q<rest-client>, [">= 0"])
    s.add_dependency(%q<rest>, [">= 0"])
    s.add_dependency(%q<bundler>, [">= 0"])
  end
end

