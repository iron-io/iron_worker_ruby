require 'appoxy_api'
require File.join(File.dirname(__FILE__), 'worker')


module SimpleWorker

    class Service < Appoxy::Api::Client

        def initialize(access_key, secret_key, options={})
            puts 'Starting SimpleWorker::Service...'
            super("http://api.simpleworkr.com/api/", access_key, secret_key, options)
        end

        # Options:
        #    - :callback_url
        def upload(filename, class_name, options={})
            mystring = nil
            file = File.open(filename, "r") do |f|
                mystring = f.read
            end
            options = {"code"=>mystring, "class_name"=>class_name}
            ret = post("code/put", options)
            ret
        end

        #
        # data: 
        def queue(class_name, data={})
            if !data.is_a?(Array)
                data = [data]
            end
            hash_to_send = {}
            hash_to_send["payload"] = data
            hash_to_send["class_name"] = class_name
            if defined?(RAILS_ENV)
                hash_to_send["rails_env"] = RAILS_ENV
            end
            return queue_raw(class_name, hash_to_send)

        end

        def queue_raw(class_name, data={})
            params = nil
            hash_to_send = data
            hash_to_send["class_name"] = class_name
            ret = post("queue/add", hash_to_send)
            ret

        end


        #
        # schedule: hash of scheduling options that can include:
        #     Required:
        #     - start_at:      Time of first run - DateTime or Time object.
        #     Optional:
        #     - run_every:     Time in seconds between runs. If ommitted, task will only run once.
        #     - delay_type:    Fixed Rate or Fixed Delay. Default is fixed_delay.
        #     - end_at:        Scheduled task will stop running after this date (optional, if ommitted, runs forever or until cancelled)
        #     - run_times:     Task will run exactly :run_times. For instance if :run_times is 5, then the task will run 5 times.
        #
        def schedule(class_name, data, schedule)
            raise "Schedule must be a hash." if !schedule.is_a? Hash
#            if !data.is_a?(Array)
#                data = [data]
#            end
            hash_to_send = {}
            hash_to_send["payload"] = data
            hash_to_send["class_name"] = class_name
            hash_to_send["schedule"] = schedule
            puts 'about to send ' + hash_to_send.inspect
            ret = post("scheduler/schedule", hash_to_send)
            ret
        end

        def cancel_schedule(scheduled_task_id)
            raise "Must include a schedule id." if scheduled_task_id.blank?
            hash_to_send = {}
            hash_to_send["scheduled_task_id"] = scheduled_task_id
            ret = post("scheduler/cancel", hash_to_send)
            ret
        end

        def get_schedules()
            hash_to_send = {}
            ret = get("scheduler/list", hash_to_send)
            ret
        end

        def status(task_id)
            data = {"task_id"=>task_id}
            ret = get("task/status", data)
            ret
        end

        def log(task_id)
            data = {"task_id"=>task_id}
            ret = get("task/log", data)
            puts 'ret=' + ret.inspect
#            ret["log"] = Base64.decode64(ret["log"])
            ret
        end


    end
end