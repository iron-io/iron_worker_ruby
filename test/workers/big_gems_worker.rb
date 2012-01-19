
RMAGICK_BYPASS_VERSION_TEST = true

class BigGemsWorker < IronWorker::Base

  merge_gem 'activesupport', {:version => '3.1.3', :require=>'active_support/core_ext'}
  require 'mysql2'
  merge_gem 'activerecord', {:version => '3.1.3', :require=>'active_record'}
  merge_gem 'actionmailer', {:version => '3.1.3', :require=>'action_mailer'}
  require 'RMagick'

  merge_gem 'timecop'

  merge_gem 'carrierwave', {:version => '0.5.8', :require => ['carrierwave', 'carrierwave/orm/activerecord']}
  merge_gem 'fog'
  #merge_gem 'friendly_id', {:version => '4.0.0.beta14'}

  def run
    log "hello"
  end
end
