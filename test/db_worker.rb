# bump..........

require 'mysql2'

class DbWorker < SimpleWorker::Base
  merge_gem 'active_record'
  merge 'db_model'


  def run

    n = DbModel.new(:name=>"jane", :age=>21)
    n.save!

    to = DbModel.first
    puts 'found: ' + to.inspect
    @object = to

    n.delete
  end

  def ob
    @object
  end


end
