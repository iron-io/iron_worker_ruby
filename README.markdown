# Introduction

To run your code in cloud you need to do three things:

- **Create code package**
- **Upload code package**
- **Queue or schedule tasks** for execution

TODO: Link to dockerworker.

While you can use [REST APIs](http://dev.iron.io/worker/reference/api) for that, it's easier to use an
IronWorker library created specifically for your language of choice, such as this gem, IronWorkerNG.

# Preparing Your Environment

You'll need to register at http://iron.io/ and get your credentials to use IronWorker. Each account can have an unlimited number of projects, so take advantage of it by creating separate projects for development, testing and production. Each project is identified by a unique project ID and requires your access token before it will perform any action, like uploading or queuing workers.

Also, you'll need a Ruby 1.9 interpreter and the IronWorker gem. Install it using following command.

```sh
gem install iron_worker
```


## Queue Up a Task for your Worker

TODO: Drop this, should use new cli tool for queueing.

You can quicky queue up a task for your worker from the command line using:

    iron_worker queue hello

Use the `-p` parameter to pass in a payload:

    iron_worker queue hello -p "{\"hi\": \"world\"}"

Use the `--wait` parameter to queue a task, wait for it to complete and print the log.

    iron_worker queue hello -p "{\"hi\": \"world\"}" --wait

### Queue up a task from code

Most commonly you'll be queuing up tasks from code though, so you can do this:

```ruby
require "iron_worker_ng"
client = IronWorkerNG::Client.new
100.times do
   client.tasks.create("hello", "foo"=>"bar")
end
```

### Setting Task Priority

TODO: Drop this, use new cli tool

You can specify priority of the task using `--priority` parameter:

```ruby
iron_worker queue hello --priority 0 # default value, lowest priority
iron_worker queue hello --priority 1 --label 'medium priority task' # medium priority
```

Value of priority parameter means the priority queue to run the task in. Valid values are 0, 1, and 2. 0 is the default.

From code you can set the priority like it done in snippet below:

```ruby
client.tasks.create("hello", some_params, priority: 2) # highest priority
```

### Setting additional Options


You can specify not only priority:

  - **priority**: Setting the priority of your job. Valid values are 0, 1, and 2. The default is 0.
  - **timeout**: The maximum runtime of your task in seconds. No task can exceed 3600 seconds (60 minutes). The default is 3600 but can be set to a shorter duration.
  - **delay**: The number of seconds to delay before actually queuing the task. Default is 0.
  - **label**: Optional text label for your task.
  - **cluster**: cluster name ex: "high-mem" or "dedicated". If not set default is set to "default" which is the public IronWorker cluster.

## Get task status


TODO: Drop, use new cli

When you call `iron_worker queue X`, you'll see the task ID in the output which you can use to get the status.

    iron_worker info task 5032f7360a4681382838e082

## Get task log


TODO: Drop, use new cli

Similar to getting status, get the task ID in the queue command output, then:

    iron_worker log 5032f7360a4681382838e082 --wait

## Retry a Task


TODO: Drop, use new cli

You can retry task by id using same payload and options:

    iron_worker retry 5032f7360a4681382838e082

or
```ruby
client.tasks.retry('5032f7360a4681382838e082', :delay => 10)

## Pause or Resume task processing


TODO: Drop, use new cli

You can temporarily pause or resume queued and scheduled tasks processing by code name:

    iron_worker pause hello

    iron_worker resume hello

or by code:
Pause or resume for the code package specified by `code_id`.

```ruby
response = client.codes.pause_task_queue('1234567890')
response = client.codes.resume_task_queue('1234567890')
```


### Debugging

To get a bunch of extra output to debug things, turn it on using:

    IronCore::Logger.logger.level = ::Logger::DEBUG


# Queue Up Tasks for Your Worker

Now that the code is uploaded, we can create/queue up tasks. You can call this over and over
for as many tasks as you want.

```ruby
client.tasks.create('MyWorker', {:client => 'Joe'})
```


# The Rest of the IronWorker API

## IronWorker::Client

You can use the `IronWorkerNG::Client` class to upload code packages, queue tasks, create schedules, and more.

### initialize(options = {})

Create a client object used for all your interactions with the IronWorker cloud.

```ruby
client = IronWorkerNG::Client.new(:token => 'IRON_IO_TOKEN', :project_id => 'IRON_IO_PROJECT_ID')
```

### codes.list(options = {})

Return an array of information about uploaded code packages. Visit http://dev.iron.io/worker/reference/api/#list_code_packages for more information about the available options and the code package object format.

```ruby
client.codes.list.each do |code|
  puts code.inspect
end
```

### codes.get(code_id)

Return information about an uploaded code package with the specified ID. Visit http://dev.iron.io/worker/reference/api/#get_info_about_a_code_package for more information about the code package object format.

```ruby
puts client.codes.get('1234567890').name
```

### codes.create(code)

Upload an `IronWorkerNG::Code::Ruby` object to the IronWorker cloud.

```ruby
client.codes.create(code)
```

### codes.delete(code_id)

Delete the code package specified by `code_id` from the IronWorker cloud.

```ruby
client.codes.delete('1234567890')
```

### codes.revisions(code_id, options = {})

Get an array of revision information for the code package specified by `code_id`. Visit http://dev.iron.io/worker/reference/api/#list_code_package_revisions for more information about the available options and the revision objects.

```ruby
client.codes.revisions('1234567890').each do |revision|
  puts revision.inspect
end
```

### codes.download(code_id, options = {})

Download the code package specified by `code_id` and return it as an array of bytes. Visit http://dev.iron.io/worker/reference/api/#download_a_code_package for more information about the available options.

```ruby
data = client.codes.download('1234567890')
```

### tasks.list(options = {})

Retrieve an array of information about your workers' tasks. Visit http://dev.iron.io/worker/reference/api/#list_tasks for more information about the available options and the task object format.

```ruby
client.tasks.list.each do |task|
  puts task.inspect
end
```

### tasks.get(task_id)

Return information about the task specified by `task_id`. Visit http://dev.iron.io/worker/reference/api/#get_info_about_a_task for more information about the task object format.

```ruby
puts client.tasks.get('1234567890').code_name
```

### tasks.create(code_name, params = {}, options = {})

Queue a new task for the code package specified by `code_name`, passing the `params` hash to it as a payload and returning a task object with only the `id` field filled. Visit http://dev.iron.io/worker/reference/api/#queue_a_task for more information about the available options.

```ruby
task = client.tasks.create('MyWorker', {:client => 'Joe'}, {:delay => 180})
puts task.id
```

### tasks.cancel(task_id)

Cancel the task specified by `task_id`.

```ruby
client.tasks.cancel('1234567890')
```

### tasks.cancel_all(code_id)

Cancel all tasks for the code package specified by `code_id`.

```ruby
client.tasks.cancel_all('1234567890')
```

### tasks.log(task_id)

Retrieve the full task log for the task specified by `task_id`. Please note that log is available only after the task has completed execution. The log will include any output to `STDOUT`.

```ruby
puts client.tasks.log('1234567890')
```

### tasks.set_progress(task_id, options = {})

Set the progress information for the task specified by `task_id`. This should be used from within workers to inform you about worker execution status, which you can retrieve with a `tasks.get` call. Visit http://dev.iron.io/worker/reference/api/#set_a_tasks_progress for more information about the available options.

```ruby
client.tasks.set_progress('1234567890', {:msg => 'Still running...'})
```

### tasks.wait_for(task_id, options = {})

Wait (block) while the task specified by `task_id` executes. Options can contain a `:sleep` parameter used to modify the delay between API invocations; the default is 5 seconds. If a block is provided (as in the example below), it will be called after each API call with the task object as parameter.

```ruby
client.tasks.wait_for('1234567890') do |task|
  puts task.msg
end
```

### schedules.list(options = {})

Return an array of scheduled tasks. Visit http://dev.iron.io/worker/reference/api/#list_scheduled_tasks for more information about the available options and the scheduled task object format.

```ruby
client.schedules.list.each do |schedule|
  puts schedule.inspect
end
```

### schedules.get(schedule_id)

Return information about the scheduled task specified by `schedule_id`. Visit http://dev.iron.io/worker/reference/api/#get_info_about_a_scheduled_task for more information about the scheduled task object format.

```ruby
puts client.schedules.get('1234567890').last_run_time
```

### schedules.create(code_name, params = {}, options = {})

Create a new scheduled task for the code package specified by `code_name`, passing the params hash to it as a data payload and returning a scheduled task object with only the `id` field filled. Visit http://dev.iron.io/worker/reference/api/#schedule_a_task for more information about the available options.

```ruby
schedule = client.schedules.create('MyWorker', {:client => 'Joe'}, {:start_at => Time.now + 3600, :run_every =>60, :priority => 0, :run_times => 100, :end_at: Time.now + 2592000, Time.now + 84600})
puts schedule.id
```

#### Scheduling Options

  - **run_every**: The amount of time, in seconds, between runs. By default, the task will only run once. run_every will return a 400 error if it is set to less than 60.
  - **end_at**: The time tasks will stop being queued.
  - **run_times**: The number of times a task will run.
  - **priority**: Setting the priority of your job. Valid values are 0, 1, and 2. The default is 0. Higher values means tasks spend less time in the queue once they come off the schedule.
  - **start_at**: The time the scheduled task should first be run.
  - **timeout**: The maximum runtime of your task in seconds. No task can exceed 3600 seconds (60 minutes). The default is 3600 but can be set to a shorter duration.
  - **delay**: The number of seconds to delay before scheduling the tasks. Default is 0.
  - **task_delay**: The number of seconds to delay before actually queuing the task. Default is 0.
  - **label**: Optional label for adding custom labels to scheduled tasks.
  - **cluster**: cluster name ex: "high-mem" or "dedicated".  This is a premium feature for customers to have access to more powerful or custom built worker solutions. Dedicated worker clusters exist for users who want to reserve a set number of workers just for their queued tasks. If not set default is set to  "default" which is the public IronWorker cluster.

### schedules.update(schedule_id, options = {})

Update a scheduled task specified by id

```ruby
client.schedules.update('545b3cb829acd33ea10016e4', {label: 'new_label'})
```

Or you can update a scheduled task for your worker from the command line using:

    iron_worker update schedule 545b3cb829acd33ea10016e4 -s '{"label": "new_label"}'

### schedules.cancel(schedule_id)

Cancel the scheduled task specified by `schedule_id`.

```ruby
client.schedules.cancel('1234567890')
```

### patch your worker using cli

If you have an uploaded worker named `super_code` with files `qux.rb, bar.rb, etc.` and want to replace the content of `bar.rb` with a local file `foo.rb`, `qux.rb` with `baz.rb` just run a command:

    iron_worker patch super_code -p 'foo.rb=bar.rb,baz.rb=lib/qux.rb.rb,foo.rb,foo2.rb'

No need to pass the same two file names `foo.rb=foo.rb`, only one `foo.rb` would be enough. Normally the patched version is put in place of the originals.
