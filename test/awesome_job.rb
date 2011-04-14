
class AwesomeJob < SimpleWorker::Base
  merge_gem 'dropbox' # , '1.2.3'
  # bumpdsfsdfdsfasdf
  merge_gem 'mongoid_i18n', :require => 'mongoid/i18n'

  def run
    begin
      s = Dropbox::Session.new('...', '...')
    rescue => ex
      log "Dropbox doesn't like it when you don't have keys"
    end
#    s.mode = :dropbox
#    s.authorizing_user = 'email@gmail.com'
#    s.authorizing_password = '...'
#    s.authorize!
#
#    tmp_file = Tempfile.new('myfile.txt')
#    tmp_file.write("blahblah")
#    tmp_file.close
#
#    s.upload tmp_file.path, 'Test'
#    tmp_file.unlink
  end
end
