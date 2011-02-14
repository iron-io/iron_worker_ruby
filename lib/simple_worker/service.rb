require 'base64'

module SimpleWorker

  class Service < Appoxy::Api::Client

    attr_accessor :config

    def initialize(access_key, secret_key, options={})
      puts 'Starting SimpleWorker::Service...'
      self.config = options[:config] if options[:config]
      super("http://api.simpleworker.com/api/", access_key, secret_key, options)
      self.host = self.config.host if self.config && self.config.host
    end

    # Options:
    #    - :callback_url
    #    - :merge => array of files to merge in with this file
    def upload(filename, class_name, options={})
      puts "Uploading #{class_name}"
      # check whether it should upload again
      tmp          = Dir.tmpdir()
      md5file      = "simple_worker_#{class_name.gsub("::", ".")}_#{access_key[0,8]}.md5"
      existing_md5 = nil
      f            = File.join(tmp, md5file)
      if File.exists?(f)
        existing_md5 = IO.read(f)
      end

      filename = build_merged_file(filename, options[:merge], options[:unmerge]) if options[:merge]

#            sys.classes[subclass].__file__
#            puts '__FILE__=' + Base.subclass.__file__.to_s
      md5      = Digest::MD5.hexdigest(File.read(filename))
#            puts "new md5=" + md5

      new_code = false
      if md5 != existing_md5
        puts "#{class_name}: new code, uploading"
        File.open(f, 'w') { |f| f.write(md5) }
        new_code = true
      else
        puts "#{class_name}: same code, not uploading"
      end

      if new_code
        mystring = nil
        file     = File.open(filename, "r") do |f|
          mystring = f.read
        end
#        mystring = Base64.encode64(mystring)
#        puts 'code=' + mystring
        options  = {"code"=>mystring, "class_name"=>class_name}
        ret      = post("code/put", options)
        ret
      end
    end

    def build_merged_file(filename, merge, unmerge)
      merge = merge.dup
      merge << filename
      #puts "merge before uniq! " + merge.inspect
      merge.uniq!
     # puts "merge after uniq! " + merge.inspect

      if unmerge
        unmerge.each do |x|
          deleted = merge.delete x
#          puts "Unmerging #{x}. Success? #{deleted}"
        end
      end

      fname2 = File.join(Dir.tmpdir(), File.basename(filename))
#            puts 'fname2=' + fname2
#            puts 'merged_file_array=' + merge.inspect
      File.open(fname2, "w") do |f|
         if SimpleWorker.config.extra_requires
           SimpleWorker.config.extra_requires.each do |r|
             f.write "require '#{r}'\n"
           end
         end
        merge.each do |m|
#          puts "merging #{m} into #{filename}"
          f.write File.open(m, 'r') { |mo| mo.read }
          f.write "\n\n"
        end
      end
      fname2
    end

    def add_sw_params(hash_to_send)
      # todo: remove secret key??  Can use worker service from within a worker without it now
      hash_to_send["sw_access_key"] = self.access_key
      hash_to_send["sw_secret_key"] = self.secret_key
    end

    # class_name: The class name of a previously upload class, eg: MySuperWorker
    # data: Arbitrary hash of your own data that your task will need to run.
    def queue(class_name, data={}, options={})
      puts "Queuing #{class_name}"
      if !data.is_a?(Array)
        data = [data]
      end
      p data
      hash_to_send               = {}
      hash_to_send["payload"]    = data
      hash_to_send["class_name"] = class_name
      hash_to_send["priority"] = options[:priority] if options[:priority]
      add_sw_params(hash_to_send)
      if defined?(RAILS_ENV)
        # todo: move this to global_attributes in railtie
        hash_to_send["rails_env"] = RAILS_ENV
      end
      return queue_raw(class_name, hash_to_send)

    end

    def queue_raw(class_name, data={})
      params                     = nil
      hash_to_send               = data
      hash_to_send["class_name"] = class_name
      ret                        = post("queue/add", hash_to_send)
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
      puts "Scheduling #{class_name}"
      raise "Schedule must be a hash." if !schedule.is_a? Hash
#            if !data.is_a?(Array)
#                data = [data]
#            end
      hash_to_send               = {}
      hash_to_send["payload"]    = data
      hash_to_send["class_name"] = class_name
      hash_to_send["schedule"]   = schedule
      add_sw_params(hash_to_send)
#            puts 'about to send ' + hash_to_send.inspect
      ret = post("scheduler/schedule", hash_to_send)
      ret
    end

    def cancel_schedule(scheduled_task_id)
      raise "Must include a schedule id." if scheduled_task_id.blank?
      hash_to_send                      = {}
      hash_to_send["scheduled_task_id"] = scheduled_task_id
      ret                               = post("scheduler/cancel", hash_to_send)
      ret
    end

    def get_schedules()
      hash_to_send = {}
      ret          = get("scheduler/list", hash_to_send)
      ret
    end

    def status(task_id)
      data = {"task_id"=>task_id}
      ret  = get("task/status", data)
      ret
    end

    def schedule_status(schedule_id)
      data = {"schedule_id"=>schedule_id}
      ret  = get("scheduler/status", data)
      ret
    end

    def log(task_id)
      data = {"task_id"=>task_id}
      ret  = get("task/log", data)
#            puts 'ret=' + ret.inspect
#            ret["log"] = Base64.decode64(ret["log"])
      ret
    end


  end

end