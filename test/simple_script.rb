require 'json'
IronWorker.merge_gem 'rest-client'

# load data
job_data = JSON.load(File.open(File.join(ENV['user_dir'], 'job_data.json')))

puts 'x=' + job_data['x']

page = RestClient.get "http://www.github.com"
puts page
puts 'All good'
