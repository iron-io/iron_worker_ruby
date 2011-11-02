Getting Started
===============

[Sign up for a SimpleWorker account][1], it's free to try!

[1]: http://www.simpleworker.com/

Install SimpleWorker Gem
------------------------

    gem install simple_worker

Configure SimpleWorker
----------------------

You really just need your token, which you can get [here][2]
[2]: http://simpleworker.com/tokens 

    SimpleWorker.configure do |config|
        config.token = TOKEN
        config.project_id = MY_PROJECT_ID
    end

Write a Worker
--------------

Here's an example worker that sends an email:

    require 'simple_worker'

    class HelloWorker < SimpleWorker::Base

        attr_accessor :name

        # This is the method that will be run
        def run
            puts "Hello #{name}!"
        end
    end

Test It Locally
---------------

Let's say someone does something in your app and you want to send an email about it.

    worker = HelloWorker.new
    worker.name = "Travis"
    worker.run_local

Once you've got it working locally, the next step is to run it on the SimpleWorker cloud.

Queue up your Worker on the SimpleWorker Cloud
----------------------------------------------

Let's say someone does something in your app and you want to send an email about it.

    worker = HelloWorker.new
    worker.name = "Travis"
    worker.queue

This will send it off to the SimpleWorker cloud.

Full Documentation
-----------------

Now that you've got your first worker running, be sure to [check out the full documentation](http://docs.simpleworker.com).
SimpleWorker can do so much more!

Discussion Group
----------------------

Join the discussion group at: https://groups.google.com/forum/?hl=en#!forum/simple_worker
