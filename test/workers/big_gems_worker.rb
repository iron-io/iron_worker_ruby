

class BigGemsWorker < SimpleWorker::Base

  merge_gem 'railties', {:version => '3.1.1', :require => 'rails'}
  require 'mysql2'
  merge_gem 'activesupport', {:version => '3.1.1', :require=>'active_support'}
  merge_gem 'activemodel', {:version => '3.1.1', :require=>'active_model'}

  merge_gem 'activerecord', {:version => '3.1.1', :require=>'active_record'}
  merge_gem 'actionmailer', {:version => '3.1.1', :require=>'action_mailer'}
  merge_gem 'actionpack', {:version => '3.1.1', :require => 'action_pack'}
  require 'RMagick'

  require 'timecop'


  merge_gem 'carrierwave', {:version => '0.5.6', :require => ['carrierwave', 'carrierwave/orm/activerecord']}
  merge_gem 'fog'
  merge_gem 'friendly_id', {:version => '4.0.0.beta14'}

  def run
    log "hello"
  end
end
