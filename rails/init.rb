puts "Initializing list of Rails models..."
SimpleWorker.configure do |config|
  path = File.join(Rails.root, 'app/models/*.rb')
  puts 'path=' + path
  config.models = Dir.glob(path)
  puts 'config.models=' + config.models.inspect
end
