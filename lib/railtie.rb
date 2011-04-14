# see http://api.rubyonrails.org/classes/Rails/Railtie.html

require 'simple_worker'
require 'rails'

module SimpleWorker
  class Railtie < Rails::Railtie
    #    railtie_name :simple_worker deprecated

    initializer "simple_worker.configure_rails_initialization" do |app|
      puts "Initializing SimpleWorker for Rails 3..."
      SimpleWorker.configure do |c2|
        puts "IN SW conf"
        models_path       = File.join(Rails.root, 'app/models/*.rb')
        c2.models         = Dir.glob(models_path)
        mailers_path      = File.join(Rails.root, 'app/mailers/*.rb')
        c2.mailers        =Dir.glob(mailers_path).collect { |m| {:filename=>m, :name => File.basename(m), :path_to_templates=>File.join(Rails.root, "app/views/#{File.basename(m, File.extname(m))}")} }
        c2.extra_requires += ['active_support/core_ext', 'active_record', 'action_mailer']
        c2.database       = Rails.configuration.database_configuration[Rails.env]
        if Bundler
          installed_gems = [{:name=>"rake", :version=>"0.8.7"},{:name=>"sqlite3-ruby", :version=>"1.3.3"}, {:name=>"simple_worker", :version=>"0.5.8"}, {:name=>"abstract", :version=>"1.0.0"}, {:name=>"builder", :version=>"2.1.2"}, {:name=>"i18n", :version=>"0.5.0"}, {:name=>"activemodel", :version=>"3.0.5"}, {:name=>"erubis", :version=>"2.6.6"}, {:name=>"rack", :version=>"1.2.2"}, {:name=>"rack-mount", :version=>"0.6.14"}, {:name=>"rack-test", :version=>"0.5.7"}, {:name=>"tzinfo", :version=>"0.3.26"}, {:name=>"actionpack", :version=>"3.0.5"}, {:name=>"mime-types", :version=>"1.16"}, {:name=>"polyglot", :version=>"0.3.1"}, {:name=>"treetop", :version=>"1.4.9"}, {:name=>"mail", :version=>"2.2.15"}, {:name=>"actionmailer", :version=>"3.0.5"}, {:name=>"arel", :version=>"2.0.9"}, {:name=>"activerecord", :version=>"3.0.5"}, {:name=>"activeresource", :version=>"3.0.5"}, {:name=>"addressable", :version=>"2.2.5"}, {:name=>"rest-client", :version=>"1.6.1"}, {:name=>"appoxy_api", :version=>"0.0.11"}, {:name=>"hashie", :version=>"1.0.0"}, {:name=>"mini_fb", :version=>"1.1.7"}, {:name=>"oauth", :version=>"0.4.4"}, {:name=>"ruby-openid", :version=>"2.1.8"}, {:name=>"http_connection", :version=>"1.4.0"}, {:name=>"uuidtools", :version=>"2.1.2"}, {:name=>"xml-simple", :version=>"1.0.15"}, {:name=>"aws", :version=>"2.4.5"}, {:name=>"simple_record", :version=>"2.1.3"}, {:name=>"appoxy_rails", :version=>"0.0.33"}, {:name=>"bundler", :version=>"1.0.10"}, {:name=>"rspec-core", :version=>"2.5.1"}, {:name=>"diff-lcs", :version=>"1.1.2"}, {:name=>"rspec-expectations", :version=>"2.5.0"}, {:name=>"rspec-mocks", :version=>"2.5.0"}, {:name=>"rspec", :version=>"2.5.0"}, {:name=>"concur", :version=>"0.0.4"}, {:name=>"multipart-post", :version=>"1.1.0"}, {:name=>"faraday", :version=>"0.5.7"}, {:name=>"hominid", :version=>"3.0.2"}, {:name=>"hoptoad_notifier", :version=>"2.4.9"}, {:name=>"local_cache", :version=>"1.2.2"}, {:name=>"multi_json", :version=>"0.0.5"}, {:name=>"net-ldap", :version=>"0.1.1"}, {:name=>"net-ssh", :version=>"2.0.23"}, {:name=>"net-sftp", :version=>"2.0.5"}, {:name=>"nokogiri", :version=>"1.4.4"}, {:name=>"oa-core", :version=>"0.2.0"}, {:name=>"oa-basic", :version=>"0.2.0"}, {:name=>"pyu-ruby-sasl", :version=>"0.0.3.2"}, {:name=>"rubyntlm", :version=>"0.1.1"}, {:name=>"oa-enterprise", :version=>"0.2.0"}, {:name=>"oa-more", :version=>"0.2.0"}, {:name=>"oauth2", :version=>"0.1.1"}, {:name=>"oa-oauth", :version=>"0.2.0"}, {:name=>"rack-openid", :version=>"1.2.0"}, {:name=>"ruby-openid-apps-discovery", :version=>"1.2.0"}, {:name=>"oa-openid", :version=>"0.2.0"}, {:name=>"omniauth", :version=>"0.2.0"}, {:name=>"thor", :version=>"0.14.6"}, {:name=>"railties", :version=>"3.0.5"}, {:name=>"rails", :version=>"3.0.5"}, {:name=>"rails", :version=>"3.0.3"}, {:name=>"recaptcha", :version=>"0.3.1"}, {:name=>"zip", :version=>"2.0.2"}, {:name=>"simple_worker", :version=>"0.5.1"}, {:name=>"validatable", :version=>"1.6.7"}]
          c2.gems        = generate_list_of_gems(installed_gems, get_required_gems)
        end
        puts "MODELS" + c2.models.inspect
        puts "MAILERS" + c2.mailers.inspect
        puts "DATABASE" + c2.database.inspect
        puts "GEMS" + c2.gems.inspect
      end

    end

    def get_required_gems
      gems_in_gemfile = Bundler.environment.dependencies.select { |d| d.groups.include?(:default) }
      gems =[]
      gems_in_gemfile.each do |dep|
        gem_info = {:name=>dep.name, :version=>dep.requirement}
        gem_info.merge!({:require=>dep.autorequire.join}) if dep.autorequire
        gem_info[:version] = Bundler.load.specs.find { |g| g.name==gem_info[:name] }.version.to_s
        gems << gem_info
      end
      gems
    end

    def generate_list_of_gems(installed_gems, required_gems)
      list_of_gems=[]
      required_gems.each do |gem|
        list_of_gems<<gem.merge!({:merge=>(!installed_gems.find { |g| g[:name]==gem[:name] && g[:version]==gem[:version] })})
      end
      list_of_gems
    end
  end
end
