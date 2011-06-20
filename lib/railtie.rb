# see http://api.rubyonrails.org/classes/Rails/Railtie.html

require 'simple_worker'
require 'rails'

module SimpleWorker
  class Railtie < Rails::Railtie

    initializer "simple_worker.configure_rails_initialization" do |app|
      SimpleWorker.logger.info  "Initializing SimpleWorker for Rails 3..."
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
      gems =[]
      specs = Bundler.load.specs
      SimpleWorker.logger.debug 'Bundler specs=' + specs.inspect
      gems_in_gemfile.each do |dep|
        next if dep.name=='rails' #monkey patch
        gem_info = {:name=>dep.name, :version=>dep.requirement}
        gem_info.merge!({:require=>dep.autorequire.join}) if dep.autorequire
        spec = specs.find { |g| g.name==gem_info[:name] }
        if spec
          gem_info[:version] = spec.version.to_s
          gems << gem_info
        else
          SimpleWorker.logger.warn "Could not find gem spec for #{gem_info[:name]}"
        end
      end
      gems
    end
  end

end
