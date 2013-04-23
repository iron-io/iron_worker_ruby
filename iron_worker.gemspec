require File.expand_path('../lib/iron_worker/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Travis Reeder"]
  gem.email         = ["travis@iron.io"]
  gem.description   = "DEPRECATED!! Use iron_worker_ng now. The official IronWorker gem for IronWorker by Iron.io. http://www.iron.io"
  gem.summary       = "DEPRECATED!! Use iron_worker_ng now. The official IronWorker gem for IronWorker by Iron.io. http://www.iron.io"
  gem.homepage      = "https://github.com/iron-io/iron_worker_ruby"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "iron_worker"
  gem.require_paths = ["lib"]
  gem.version       = IronWorker::VERSION

  gem.required_rubygems_version = ">= 1.3.6"
  gem.required_ruby_version = Gem::Requirement.new(">= 1.9")
  gem.add_runtime_dependency "iron_core", ">= 0.5.1"

  gem.add_runtime_dependency 'zip'
  gem.add_runtime_dependency 'rest-client'
  gem.add_runtime_dependency 'rest'
  gem.add_runtime_dependency 'bundler'

end

