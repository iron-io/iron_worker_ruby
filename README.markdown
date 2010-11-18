Using Simple Worker

Getting Started
===============

Configure SimpleWorker
----------------------

You really just need your access keys.

    SimpleWorker.configure do |config|
        config.access_key = ACCESS_KEY
        config.secret_key = SECRET_KEY
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
    **worker.run**

Queue up your Worker
--------------------

Let's say someone does something in your app and you want to send an email about it.

    worker = EmailWorker.new
    worker.to = current_user.email
    worker.subject = "Here is your mail!"
    worker.body = "This is the body"
    **worker.queue**

Schedule your Worker
--------------------

There are two scenarios here, one is the scenario where you want something to happen due to a user
action in your application. This is almost the same as queuing your worker.

    worker = EmailWorker.new
    worker.to = current_user.email
    worker.subject = "Here is your mail!"
    worker.body = "This is the body"
    **worker.schedule(:start_at=>1.hours.since)**



Schedule your Worker Recurring
------------------------------

The alternative is when you want to user it like Cron. In this case you'll probably
want to write a script that will schedule, you don't want to schedule it everytime your
app starts or anything so best to keep it external.

Create a file called 'schedule_email_worker.rb' and add this:

    require 'simple_worker'

    worker = EmailWorker.new
    worker.to = current_user.email
    worker.subject = "Here is your mail!"
    worker.body = "This is the body"
    worker.schedule(:start_at=>1.hours.since, :run_every=>3600)

Now run it and your worker will be scheduled to run every hour.

SimpleWorker on Rails
---------------------

SimpleWorker only supports Rails 3+.

Setup:

- Make a workers directory at RAILS_ROOT/app/workers.
- In application.rb, uncomment config.autoload_paths and put:

    config.autoload_paths += %W(#{config.paths.app}/workers)

Now you can use your workers like their part of your app!


Configuration Options
---------------------

### Global Attributes

These are attributes that can be set as part of your config block then will be set on
all your worker objects automatically. This is particularly good for things like database
connection info or things that you would need to use across the board.

Eg:

    config.global_attributes[:db_user] = "sa"
    config.global_attributes[:db_pass] = "pass"

Then in your worker, you must have:

    attr_accessor :db_user, :db_pass

