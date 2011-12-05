# see http://api.rubyonrails.org/classes/Rails/Railtie.html

require 'iron_worker'
require 'rails'

module IronWorker
  class Railtie < Rails::Railtie


    initializer "iron_worker.configure_rails_initialization" do |app|

    end


  end
end
