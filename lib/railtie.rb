# see http://api.rubyonrails.org/classes/Rails/Railtie.html

require 'simple_worker'
require 'rails'

module SimpleWorker
  class Railtie < Rails::Railtie

    initializer "simple_worker.configure_rails_initialization" do |app|
      SimpleWorker.logger.info "Initializing SimpleWorker for Rails 3..."
      start_time = Time.now
      SimpleWorker.configure do |c2|
        models_path = File.join(Rails.root, 'app/models/*.rb')
        c2.models = Dir.glob(models_path)
        mailers_path = File.join(Rails.root, 'app/mailers/*.rb')
        c2.mailers = Dir.glob(mailers_path).collect { |m| {:filename=>m, :name => File.basename(m), :path_to_templates=>File.join(Rails.root, "app/views/#{File.basename(m, File.extname(m))}")} }
        c2.extra_requires += ['active_support/core_ext', 'active_record', 'action_mailer']
        c2.database = Rails.configuration.database_configuration[Rails.env]
        c2.gems = get_required_gems if defined?(Bundler)
        SimpleWorker.logger.debug "MODELS " + c2.models.inspect
        SimpleWorker.logger.debug "MAILERS " + c2.mailers.inspect
        SimpleWorker.logger.debug "DATABASE " + c2.database.inspect
        SimpleWorker.logger.debug "GEMS " + c2.gems.inspect
      end
      end_time = Time.now
      SimpleWorker.logger.info "SimpleWorker initialized. Duration: #{((end_time.to_f-start_time.to_f) * 1000.0).to_i} ms"

    end

    def get_required_gems
      gems_in_gemfile = Bundler.environment.dependencies.select { |d| d.groups.include?(:default) }
      puts 'gems in gemfile=' + gems_in_gemfile.inspect
      gems =[]
      specs = Bundler.load.specs
      SimpleWorker.logger.debug 'Bundler specs=' + specs.inspect
      specs.each do |spec|
        puts 'spec=' + spec.inspect
        p spec.methods
#        next if dep.name=='rails' #monkey patch
        gem_info = {:name=>spec.name, :version=>spec.version}
        gem_info[:auto_merged] = true
# Now find dependency in gemfile in case user set the require
        dep = gems_in_gemfile.find { |g| g.name == gem_info[:name] }
        if dep
          puts 'dep found in gemfile: ' + dep.inspect
          puts 'autorequire=' + dep.autorequire.inspect
          gem_info[:require] = dep.autorequire if dep.autorequire
#        spec = specs.find { |g| g.name==gem_info[:name] }
        end
        gem_info[:version] = spec.version.to_s
        gems << gem_info
        path = SimpleWorker::Service.get_gem_path(gem_info)
        if path
          gem_info[:path] = path
          if gem_info[:require].nil? && dep
            # see if we should try to require this in our worker
            require_path = gem_info[:path] + "/#{gem_info[:name]}.rb"
            puts "require_path=" + require_path
            if File.exists?(require_path)
              puts "File exists for require"
              gem_info[:require] = gem_info[:name]
            else
              puts "no require"
#              gem_info[:no_require] = true
            end
          end
        end
#        else
#          SimpleWorker.logger.warn "Could not find gem spec for #{gem_info[:name]}"
#          raise "Could not find gem spec for #{gem_info[:name]}"
#        end
      end
      gems
    end

  end
end
