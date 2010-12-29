puts "Initializing list of Rails models..."
SimpleWorker.configure do |config|
  config.models = Dir.glob(Rails.root + '/app/models/*.rb')
end
