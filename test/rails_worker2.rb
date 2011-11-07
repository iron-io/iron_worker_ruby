
# bump......
class RailsWorker2 < SimpleWorker::Base

  def run
    puts "I am #2. hello rails! env=#{Rails.env}"

  end
end

