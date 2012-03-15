
# bump......
class RailsWorker2 < IronWorker::Base
  attr_accessor :x

  def run
    puts "I am #2. hello rails! env=#{Rails.env}"
    puts "x=#{x}"

  end
end

