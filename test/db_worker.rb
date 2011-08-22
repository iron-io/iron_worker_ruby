require 'mysql2'
require 'active_record'
# bump........
class DbWorker < SimpleWorker::Base
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
