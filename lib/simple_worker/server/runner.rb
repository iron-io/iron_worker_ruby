# This is the file that gets executed on the server.


def init_database_connection(sw_config)
  if sw_config
    db_config = sw_config['database']
    if db_config
      #@logger.info "Connecting to database using ActiveRecord..."
      require 'active_record'
      ActiveRecord::Base.establish_connection(db_config)
    end
  end
end

def init_mailer(sw_config)
  if sw_config
    mailer_config = sw_config['mailer']
    if mailer_config
      require 'action_mailer'
      ActionMailer::Base.raise_delivery_errors = true
      ActionMailer::Base.smtp_settings = mailer_config
      ActionMailer::Base.delivery_method = :smtp
    end
  end
end

def get_class_to_run(class_name)
  runner_class = constantize(class_name)
  return runner_class
end

# File activesupport/lib/active_support/inflector/methods.rb, line 107
# Shoutout to the MIT License
def constantize(camel_cased_word)
  names = camel_cased_word.split('::')
  names.shift if names.empty? || names.first.empty?

  constant = Object
  names.each do |name|
    constant = constant.const_defined?(name) ? constant.const_get(name) : constant.const_missing(name)
  end
  constant
end

def init_runner(runner_class, job_data, user_dir)
  # ensure initialize takes no arguments
  init_arity = runner_class.instance_method(:initialize).arity
  if init_arity == 0 || init_arity == -1
    # good. -1 can be if it's not defined at all
  else
    raise SimpleWorker::InvalidWorkerError, "Worker initialize method must accept zero arguments."
  end
  runner = runner_class.new
  runner.instance_variable_set(:@job_data, job_data)
  runner.instance_variable_set(:@sw_config, job_data['sw_config'])
  runner.instance_variable_set(:@user_dir, user_dir)
  runner.sw_set_data(job_data)
  runner
end

def init_worker_service_for_runner(job_data)
  SimpleWorker.configure do |config|
    sw_config = job_data['sw_config']
    config.token = sw_config['token']
    config.project_id = sw_config['project_id']
    #puts 'Setting host to ' + host.inspect
    config.host = sw_config['host'] if sw_config['host']
    config.host = sw_config['port'] if sw_config['port']
    db_config = sw_config['database']
    if db_config
      config.database = db_config
    end
    mailer_config = sw_config['mailer']
    if mailer_config && config.respond_to?(:mailer)
      config.mailer = mailer_config
    end
    config.global_attributes = sw_config['global_attributes'] if sw_config['global_attributes']
  end
end

# SimpleWorker.logger.level ==  Logger::DEBUG
run_data = JSON.load(File.open(run_data_file))
# Load in job data
job_data = JSON.load(File.open(job_data_file))
job_data.merge!(run_data)
SimpleWorker.logger.debug 'job_data=' + job_data.inspect

sw_config = job_data['sw_config']
init_database_connection(sw_config)
init_mailer(sw_config)
SimpleWorker.disable_queueing()
runner_class = get_class_to_run(job_data['class_name'])
SimpleWorker.running_class = runner_class
runner = init_runner(runner_class, job_data, dirname)
init_worker_service_for_runner(job_data)
SimpleWorker.enable_queueing()

# Let's run it!
runner_return_data = runner.run
