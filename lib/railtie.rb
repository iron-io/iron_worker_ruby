# see http://api.rubyonrails.org/classes/Rails/Railtie.html

require 'simple_worker'
require 'rails'

module SimpleWorker
  class Railtie < Rails::Railtie
    railtie_name :simple_worker

    initializer "simple_worker.configure_rails_initialization" do |app|
      puts 'railtie'
      puts "Initializing list of Rails models..."
      SimpleWorker.configure do |c2|
#  path = File.join(File.dirname(caller[0]), '..', 'app/models/*.rb')
        path = File.join(Rails.root, 'app/models/*.rb')
        puts 'path=' + path
        c2.models = Dir.glob(path)
        puts 'config.models=' + c2.models.inspect
      end

    end
  end
end
