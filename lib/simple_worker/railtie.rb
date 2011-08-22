# see http://api.rubyonrails.org/classes/Rails/Railtie.html

require 'simple_worker'
require 'rails'

module SimpleWorker
  class Railtie < Rails::Railtie


    initializer "simple_worker.configure_rails_initialization" do |app|

    end


  end
end
