# see http://api.rubyonrails.org/classes/Rails/Railtie.html

require 'simple_worker'
require 'rails'

module SimpleWorker
  class Railtie < Rails::Railtie
#    railtie_name :simple_worker deprecated

    initializer "simple_worker.configure_rails_initialization" do |app|
      puts 'railtie'
      puts "Initializing list of Rails models..."
      SimpleWorker.configure do |c2|
        path = File.join(Rails.root, 'app/models/*.rb')
        puts 'path=' + path
        c2.models = Dir.glob(path)
        c2.extra_requires += ['active_support/core_ext', 'active_record', 'action_mailer']
        puts 'config.models=' + c2.models.inspect
      end

    end
  end
end
