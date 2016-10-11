require File.expand_path('../lib/iron_worker/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Travis Reeder"]
  gem.email         = ["travis@iron.io"]
  gem.description   = "The official IronWorker gem for IronWorker by Iron.io. http://iron.io"
  gem.summary       = "The official IronWorker gem for IronWorker by Iron.io. http://iron.io"
  gem.homepage      = "https://github.com/iron-io/iron_worker_ruby"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "iron_worker"
  gem.require_paths = ["lib"]
  gem.version       = IronWorker::VERSION

  gem.required_rubygems_version = ">= 1.3.6"
  gem.required_ruby_version = Gem::Requirement.new(">= 1.9")
  gem.add_runtime_dependency "iron_core", ">= 1.0.12", '< 2'
  gem.add_runtime_dependency 'rest', '~> 3.0', ">= 3.0.8"
  gem.add_runtime_dependency "json", "~> 1.8", "> 1.8.1"

end
