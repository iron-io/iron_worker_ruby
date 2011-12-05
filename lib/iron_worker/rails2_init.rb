#puts "Initializing list of Rails models..."
IronWorker.configure do |config|
  path = File.join(Rails.root, 'app/models/*.rb')
#  puts 'path=' + path
  config.models = Dir.glob(path)
  config.extra_requires += ['active_support/core_ext', 'active_record', 'action_mailer']
#  puts 'config.models=' + config.models.inspect
end
