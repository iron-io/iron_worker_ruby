# see http://api.rubyonrails.org/classes/Rails/Railtie.html

require 'simple_worker'
require 'rails'

module SimpleWorker
  class Railtie < Rails::Railtie
    #    railtie_name :simple_worker deprecated

    initializer "simple_worker.configure_rails_initialization" do |app|
      puts "Initializing SimpleWorker for Rails 3..."
      SimpleWorker.configure do |c2|
        models_path       = File.join(Rails.root, 'app/models/*.rb')
        c2.models         = Dir.glob(models_path)
        mailers_path      = File.join(Rails.root, 'app/mailers/*.rb')
        c2.mailers        =Dir.glob(mailers_path).collect { |m| {:filename=>m, :name => File.basename(m), :path_to_templates=>File.join(Rails.root, "app/views/#{File.basename(m, File.extname(m))}")} }
        c2.extra_requires += ['active_support/core_ext', 'active_record', 'action_mailer']
        c2.database       = Rails.configuration.database_configuration[Rails.env]
        c2.gems = get_required_gems if Bundler
        puts "MODELS" + c2.models.inspect
        puts "MAILERS" + c2.mailers.inspect
        puts "DATABASE" + c2.database.inspect
        puts "GEMS" + c2.gems.inspect
      end
    end

    def get_required_gems
      gems_in_gemfile = Bundler.environment.dependencies.select { |d| d.groups.include?(:default) }
      gems            =[]
      gems_in_gemfile.each do |dep|
        next if dep.name=='rails' #monkey patch
        gem_info = {:name=>dep.name, :version=>dep.requirement}
        gem_info.merge!({:require=>dep.autorequire.join}) if dep.autorequire
        gem_info[:version] = Bundler.load.specs.find { |g| g.name==gem_info[:name] }.version.to_s
        gems << gem_info
      end
      gems
    end
  end

end
