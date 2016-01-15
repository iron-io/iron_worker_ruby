# Introduction

To run your code in cloud you need to do three things:

- **Create code package**
- **Upload code package**
- **Queue or schedule tasks** for execution

You can read how to create, package and upload your worker here: http://dev.iron.io/worker/getting_started/

This gem has two parts to it, one to access the [IronWorker API](http://dev.iron.io/worker/reference/api) and
the other to help you with your Ruby IronWorker's.

# Preparing Your Environment

You'll need to register at http://iron.io/ and get your credentials to use IronWorker. Each account can have an unlimited number
 of projects, so take advantage of it by creating separate projects for development, testing and production. 
 Each project is identified by a unique project ID and requires your access token before it will perform any action, 
 like uploading or queuing workers.

Install using the following command.

```sh
gem install iron_worker
```

# IronWorker Helper Functions

These functions will help you read in worker payloads and things for when your worker is running. To use these functions
simple require this gem in your worker and then use the helper functions `IronWorker.payload`, `IronWorker.config` and 
`IronWorker.id`. For example, this is a complete IronWorker script:

```ruby
require 'iron_worker'

puts "Here is the payload: #{IronWorker.payload}"
puts "Here is the config: #{IronWorker.config}"
```

# The IronWorker API

This client will enable you to use the IronWorker API in Ruby. 
Full API documentation is here: http://dev.iron.io/worker/reference/api/

## IronWorker::Client

You can use the `IronWorker::Client` class to upload code packages, queue tasks, create schedules, and more.

### initialize(options = {})

Create a client object used for all your interactions with the IronWorker cloud.

```ruby
client = IronWorker::Client.new(:token => 'IRON_IO_TOKEN', :project_id => 'IRON_IO_PROJECT_ID')
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

Upload an `IronWorker::Code::Ruby` object to the IronWorker cloud.

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

### tasks.bulk_create(code_name, array_of_params = [], options = {})

Queue more than 1 tasks in a single api call for the code package specified by `code_name`, passing an array of params/payloads and returning a tasks object with the ids of each task queued.
Visit http://dev.iron.io/worker/reference/api/#queue_a_task for more information about the available options.

```ruby
task_ids = client.tasks.bulk_create('hello_ruby', [{:hello => "world"}, {:hello => "world"}, {:hello => "world"}], {:cluster => "mem1"} )
puts tasks_ids
# => #<OpenStruct tasks=[{"id"=>"54cc11b8855dc73d9209ce0d"}, {"id"=>"54cc11b8855dc73d9209ce0e"}, {"id"=>"54cc11b8855dc73d9209ce0f"}}], msg="Queued up">
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
