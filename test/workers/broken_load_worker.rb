

class BrokenLoadWorker < SimpleWorker::Base
  #merge_gem 'railties', {:version => '3.0.9', :require => 'rails'}
  require 'mysql2'
  merge_gem 'activesupport', {:version => '3.0.9', :require=>'active_support'}
  merge_gem 'activemodel', {:version => '3.0.9', :require=>'active_model'}

  merge_gem 'activerecord', {:version => '3.0.9', :require=>'active_record'}
  merge_gem 'actionmailer', {:version => '3.0.9', :require=>'action_mailer'}
  merge_gem 'actionpack', {:version => '3.0.9', :require => 'action_pack'}
  require 'RMagick'

  merge_gem 'carrierwave', {:version => '0.5.6', :require => ['carrierwave', 'carrierwave/orm/activerecord']}
  merge_gem 'fog'
  merge_gem 'friendly_id', {:version => '4.0.0.beta14'}
  #merge_gem 'haml', :require => ['haml', 'haml/template/plugin']
  #merge_gem 'json'


  #merge_gem 'sendgrid', '1.0.0'
  #merge_gem 'acts_as_relation', {:version => '0.0.5'}
  #merge_gem 'handsoap'
  #merge_gem 'nokogiri', {:version => '1.5.0'}
  #merge_gem 'curb'
  #merge_gem 'bronto_client', {:version => '0.1.2'}
  #merge_gem 'valium'
  #merge_gem 'money'
  #merge_gem 'state_machine'

  def run
    log "hello"
  end
end
