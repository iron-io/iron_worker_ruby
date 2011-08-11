KNOWN ISSUES IN NEW VERSION
=====

- Cancel chain will not work because we don't have parent task it. Do we need it though?
We could just allow kill all by class name and that would be sufficient? (see runner.rb add_sw_params)




Getting Started
===============

[Sign up for a SimpleWorker account][1], it's free to try!

[1]: http://www.simpleworker.com/

Install SimpleWorker Gem
------------------------

    gem install simple_worker

Configure SimpleWorker
----------------------

You really just need your access keys.

    SimpleWorker.configure do |config|
        config.access_key = ACCESS_KEY
        config.secret_key = SECRET_KEY
    end


Configure SimpleWorker in Rails
----------------------

If you're using Rails you could set additional config option - "auto_merge=true".
It will automatically merge all models,mailers,gems and database configuration from your Rails app.

    SimpleWorker.configure do |config|
        config.access_key = ACCESS_KEY
        config.secret_key = SECRET_KEY
        config.auto_merge = true
    end


Write a Worker
--------------

Here's an example worker that sends an email:

    require 'simple_worker'

    class EmailWorker < SimpleWorker::Base

        attr_accessor :to, :subject, :body

        # This is the method that will be run
        def run
            send_email(:to=>to, :subject=>subject, :body=>body)
        end

        def send_email
            # Put sending code here
        end
    end

Test It Locally
---------------

Let's say someone does something in your app and you want to send an email about it.

    worker = EmailWorker.new
    worker.to = current_user.email
    worker.subject = "Here is your mail!"
    worker.body = "This is the body"
    worker.run_local

Once you've got it working locally, the next step is to run it on the SimpleWorker cloud.

Queue up your Worker on the SimpleWorker Cloud
----------------------------------------------

Let's say someone does something in your app and you want to send an email about it.

    worker = EmailWorker.new
    worker.to = current_user.email
    worker.subject = "Here is your mail!"
    worker.body = "This is the body"
    worker.queue

This will send it off to the SimpleWorker cloud.

Setting Priority
----------------------------------------------

Simply define the priority in your queue command.

    worker.queue(:priority=>1)

Default priority is 0 and we currently support priority 0, 1, 2. See [pricing page](http://www.simpleworker.com/pricing)
for more information on priorites.


Schedule your Worker
--------------------

There are two scenarios here, one is the scenario where you want something to happen due to a user
action in your application. This is almost the same as queuing your worker.

    worker = EmailWorker.new
    worker.to = current_user.email
    worker.subject = "Here is your mail!"
    worker.body = "This is the body"
    worker.schedule(:start_at=>1.hours.since)

By default, if you call `schedule` more than once for the same worker class, the new schedule will replace the old one. If you'd
like multiple schedules for the same class, provide a `:name` parameter:

    worker.schedule(:name=>"EmailWorkerDaily", :start_at=>......)

You can also set priority for scheduled jobs:

    worker.schedule(:priority=>1, ....)


Check Status
------------

If you still have access to the worker object, just call:

    worker.status

If you only have the job ID, call:

    SimpleWorker.service.status(job_id)

This will return a hash like:

     {"task_id"=>"ece460ce-12d8-11e0-8e15-12313b0440c6",
     "status"=>"running",
     "msg"=>nil,
     "start_time"=>"2010-12-28T23:19:36+00:00",
     "end_time"=>nil,
     "duration"=>nil,
     "progress"=>{"percent"=>25}}

There is also a convenience method `worker.wait_until_complete` that will wait until the status returned is completed or error.

Logging
-------

In your worker, just call the log method with the string you want logged:

    log "Starting to do something..."

The log will be available for viewing via the SimpleWorker UI or via log in the API:

    SimpleWorker.service.log(job_id)

or if you still have a handle to your worker object:

    worker.get_log

Setting Progress
----------------

This is just a way to let your users know where the job is at if required.

    set_progress(:percent => 25, :message => "We are a quarter of the way there!")

You can actually put anything in this hash and it will be returned with a call to status. We recommend using
the format above for consistency and to get some additional features where we look for these values.

Schedule a Recurring Job - CRON
------------------------------

The alternative is when you want to user it like Cron. In this case you'll probably
want to write a script that will schedule, you don't want to schedule it everytime your
app starts or anything so best to keep it external.

Create a file called 'schedule_email_worker.rb' and add this:

    require 'simple_worker'
    require_relative 'email_worker'

    worker = EmailWorker.new
    worker.to = current_user.email
    worker.subject = "Here is your mail!"
    worker.body = "This is the body"
    worker.schedule(:start_at=>1.hours.since, :run_every=>3600)

Now run it and your worker will be scheduled to run every hour.

SimpleWorker on Rails
---------------------

Rails 2.X:

    config.gem 'simple_worker'

Rails 3.X:

    gem 'simple_worker'

Now you can use your workers like they're part of your app!  We recommend putting your worker classes in
/app/workers path.  

Configuring a Database Connection
---------------------------------

Although you could easily do this in your worker, this makes it a bit more convenient and more importantly
it will create the connection for you. If you are using Rails 3, you just need to add one line:

    config.database = Rails.configuration.database_configuration[Rails.env]

For non Rails 3, you would add the following to your SimpleWorker config:

    config.database = {
      :adapter => "mysql2",
      :host => "localhost",
      :database => "appdb",
      :username => "appuser",
      :password => "secret"
    }

Then before you job is run, SimpleWorker will establish the ActiveRecord connection.

Including/Merging other Ruby Classes
------------------------------------

If you are using the Rails setup above, you can probably skip this as your models will automatically be merged.

    class AvgWorker < SimpleWorker::Base

        attr_accessor :aws_access_key,
                      :aws_secret_key,
                      :s3_suffix

        merge File.join(File.dirname(__FILE__), "..", "app", "models", "user.rb")
        merge File.join(File.dirname(__FILE__), "..", "app", "models", "account")

Or simpler yet, try using relative paths:

    merge "../models/user"
    merge "../models/account.rb"

Also you could use wildcards and path in merge_folder

    merge_folder "./foldername/"     #will merge all *.rb files from foldername
    merge_folder "../lib/**/"        # will merge all *.rb files from lib and all subdirectories

The opposite can be done as well with "unmerge" and can be useful when using Rails to exclude classes that are automatically
merged.


Merging other Workers
---------------------

Merging other workers is a bit different than merging other code like above because they will be
uploaded separately and treated as distinctly separate workers.

    merge_worker "./other_worker.rb", "OtherWorker"

Merging Mailers
---------------------

You could easily merge mailers you're using in your application.

    merge_mailer 'mailer_file' #if your mailer's templates are placed in default path
    #or
    merge_mailer 'mailer_file', {:path_to_templates=>"templates_path"}#if you're using mailer outside of rails with custom templates path

if you already set auto_merge=true all your mailers already merged.

Merging Gems
---------------------

This allows you to use any gem you'd like with SimpleWorker. This uses the same syntax as bundler gem files.

    # merge latest version of the gem
    merge_gem "some_gem"
    # or specify specific version
    merge_gem "some_gem_with_version", "1.2.3"
    # or if gem has poor naming scheme
    merge_gem 'mongoid_i18n', :require => 'mongoid/i18n'

[Check here for more info on merge_gem](http://support.simpleworker.com/kb/working-with-simpleworker/merging-gems-into-your-worker).


Configuration Options
---------------------

### Global Attributes

These are attributes that can be set as part of your config block then will be set on
all your worker objects automatically. This is particularly good for things like database
connection info or things that you would need to use across the board.

Eg:

    config.global_attributes[:db_user] = "sa"
    config.global_attributes[:db_pass] = "pass"

Then in your worker, you would have the attributes defined:

    attr_accessor :db_user, :db_pass


Development of the Gem
----------------------

Join the discussion group at: https://groups.google.com/forum/?hl=en#!forum/simple_worker
