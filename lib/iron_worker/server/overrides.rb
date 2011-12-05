# This is used when a bad worker is uploaded.

module IronWorker

  class InvalidWorkerError < StandardError;
  end

  class << self
    def running_class=(rc)
      @running_class = rc
    end

    def running_class
      @running_class
    end

    def task_data=(td)
      @task_data = td
    end

    def task_data
      @task_data
    end
  end

  def self.disable_queueing()
    @queueing_enabled = false
  end

  def self.enable_queueing()
    @queueing_enabled = true
  end

  def self.queueing_enabled?
    @queueing_enabled
  end

  class Config

    def merge(file)
    end

    def unmerge(file)
    end

    def merge_gem(gem_name, options={})
    end

    def unmerge_gem(gem_name)
    end

    def merge_folder(path)
    end


  end


  class Base

    class << self

      def merge(*files)
      end

      def merge_folder(path)
      end

      def unmerge(*files)
        # ignore this here
      end

      def merge_mailer(mailer, params=nil)
      end

      def merge_gem(gem, version=nil)
      end

      def merge_worker(file, class_name)

      end

    end

    def is_remote?
      true
    end

    #:todo remove this method later, when new iron_worker gem will be released
    def is_local?
      !is_remote?
    end

    def log(str)
      puts str.to_s
    end

    def set_progress(hash)
      #puts 'set_progress self=' + self.inspect
      IronWorker.service.set_progress(self.task_id, hash)
    end

    def something
      puts 'which class? ' + self.class.name
    end

    def user_dir
#      puts 'user_dir=' + @context.user_dir.to_s
      @user_dir || "./"
    end

    def sw_set_data(data)
      if data["attr_encoded"]
        # new way, attributes are base 64 encoded
        data = JSON.parse(Base64.decode64(data["attr_encoded"]))
      end

      data.each_pair do |k, v|
        next unless k[0] == "@"
#        puts "setting instance_variable #{k}=#{v}"
        self.instance_variable_set(k, v)
      end

    end

    def upload_if_needed(options={})
      puts "No uploading in worker service."
    end

    alias_method :orig_queue, :queue
    alias_method :orig_schedule, :schedule
    alias_method :orig_status, :status

    def queue(options={})
      if IronWorker.queueing_enabled? && (!same_clazz? || options[:recursive])
        orig_queue(options)
#        data = sw_get_data()
#        queue_other(self.class.name, data)
      else
        log (IronWorker.queueing_enabled? ? "WARNING: Recursion detected in queueing, pass in :recursive=>true to bypass this." : "Queuing disabled while loading.")
      end
    end

    def schedule(schedule)
      if IronWorker.queueing_enabled? && (!same_clazz? || schedule[:recursive])
        orig_schedule(schedule)
#        data = sw_get_data()
#        schedule_other(self.class.name, data, schedule)
      else
        log (IronWorker.queueing_enabled? ? "WARNING: Recursion detected in scheduling." : "Scheduling disabled while loading.")
      end

    end

    def status
      if IronWorker.queueing_enabled?
        orig_status
      else
        log "Status disabled while loading."
      end
    end

    def same_clazz?
      IronWorker.running_class == self.class
    end

  end


  class Service < IronWorker::Api::Client
    def upload(filename, class_name, options={})
      #puts "Skipping upload, We don't upload from run.rb!"
      # don't upload, should already be here.
    end

    def add_sw_params(hash_to_send)
      hash_to_send["token"] = self.config.token
      hash_to_send["project_id"] = self.config.project_id
      hash_to_send["api_version"] = IronWorker.api_version
    end
  end


  module UsedInWorker
    def log(str)
      puts str.to_s
    end
  end


end
