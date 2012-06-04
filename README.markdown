Getting Started
===============

[Sign up for a IronWorker account][1], it's free to try!

[1]: http://www.iron.io/

NOTE: The next generation IronWorker gem, `iron_worker_ng` is at: https://github.com/iron-io/iron_worker_ruby_ng. 
We recommend using that one going forward. This one still works, but we'll be putting most of our effort into the new
one. It also includes our new IronWorker command line interface (CLI) which is... awesome. ;) You can [read more about 
that here](http://blog.iron.io/2012/05/new-ironworker-command-line-interface.html). 

Install IronWorker Gem
------------------------

    gem install iron_worker

Configure IronWorker
----------------------

You really just need your token, which you can get [here][2]
[2]: http://hud.iron.io/tokens

    IronWorker.configure do |config|
        config.token = TOKEN
        config.project_id = MY_PROJECT_ID
    end

Write a Worker
--------------

Here's an example worker that sends an email:

    require 'iron_worker'

    class HelloWorker < IronWorker::Base

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

Once you've got it working locally, the next step is to run it on the IronWorker cloud.

Queue up your Worker on the IronWorker Cloud
----------------------------------------------

Let's say someone does something in your app and you want to send an email about it.

    worker = HelloWorker.new
    worker.name = "Travis"
    worker.queue

This will send it off to the IronWorker cloud.

Full Documentation
-----------------

Now that you've got your first worker running, be sure to [check out the full documentation](https://github.com/iron-io/iron_worker_ruby/wiki).
IronWorker can do so much more! 

And check out the [Iron.io Dev Center](http://dev.iron.io) for full IronWorker API documentation and and support for other languages.
