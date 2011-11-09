
# bump......
class RailsWorker2 < SimpleWorker::Base
  attr_accessor :x

  def run
    puts "I am #2. hello rails! env=#{Rails.env}"
    puts "x=#{x}"

  end
end

