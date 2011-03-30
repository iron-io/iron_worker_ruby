require 'digest/md5'
require 'base64'

module SimpleWorker

  class Base

    attr_accessor :task_set_id, :task_id, :schedule_id

    class << self
      attr_accessor :subclass, :caller_file
      @merged = []
      @merged_workers = []
      @merged_gems = []
      @unmerged = []

      def reset!
        @merged = []
        @merged_workers = []
        @merged_gems = []
        @unmerged = []
      end

      def inherited(subclass)
        subclass.reset!

#                puts "subclass.inspect=" + subclass.inspect
#                puts 'existing caller=' + (subclass.instance_variable_defined?(:@caller_file) ? subclass.instance_variable_get(:@caller_file).inspect : "nil")
#                puts "caller=" + caller.inspect
#                splits = caller[0].split(":")
#                caller_file = splits[0] + ":" + splits[1]
        caller_file = caller[0][0...(caller[0].index(":in"))]
        caller_file = caller_file[0...(caller_file.rindex(":"))]
        #        puts 'caller_file=' + caller_file
        # don't need these class_variables anymore probably
        subclass.instance_variable_set(:@caller_file, caller_file)

        super
      end

      def check_for_file(f)
        f = f.to_str
        unless ends_with?(f, ".rb")
          f << ".rb"
        end
        exists = false
        if File.exist? f
          exists = true
        else
          # try relative
#          p caller
          f2 = File.join(File.dirname(caller[3]), f)
          puts 'f2=' + f2
          if File.exist? f2
            exists = true
            f = f2
          end
        end
        unless exists
          raise "File not found: " + f
        end
        f = File.expand_path(f)
        require f
        f
      end

      # merges the specified gem.
      def merge_gem(gem_name, version=nil)
        gem_info = {:name=>gem_name}
        if version.is_a?(Hash)
          gem_info.merge!(version)
        else
          gem_info[:version] = version
        end
        @merged_gems << gem_info
        require gem_info[:require] || gem_name
      end

      # merges the specified files.
      # todo: don't allow multiple files per merge, just one like require
      def merge(*files)
        files.each do |f|
          f = check_for_file(f)
          @merged << f
        end
      end

      # Opposite of merge, this will omit the files you specify from being merged in. Useful in Rails apps
      # where a lot of things are auto-merged by default like your models.
      def unmerge(*files)
        files.each do |f|
          f = check_for_file(f)
          @unmerged << f
        end
      end

      def ends_with?(s, suffix)
        suffix = suffix.to_s
        s[-suffix.length, suffix.length] == suffix
      end

      # Use this to merge in other workers. These are treated differently the normal merged files because
      # they will be uploaded separately and treated as distinctly separate workers.
      #
      # file: This is the path to the file, just like merge.
      # class_name: eg: 'MyWorker'. 
      def merge_worker(file, class_name)
#        puts 'merge_worker in ' + self.name
        merge(file)
        @merged_workers << [File.expand_path(file), class_name]
      end
    end


    def log(str)
      puts str.to_s
    end

    def user_dir
      "./"
    end

    def set_progress(hash)
      puts 'set_progress: ' + hash.inspect
    end

    def who_am_i?
      return self.class.name
    end

    def uploaded?
      self.class.instance_variable_defined?(:@uploaded) && self.class.instance_variable_get(:@uploaded)
    end

    # Call this if you want to run locally and get some extra features from this gem like global attributes.
    def run_local
      # puts 'run_local'
      set_auto_attributes
      init_database
      begin
        run
      rescue => ex
        if self.respond_to?(:rescue_all)
          rescue_all(ex)
        else
          raise ex
        end
      end
    end

    def init_database
      if SimpleWorker.config.database
        require 'active_record'
        if !ActiveRecord::Base.connected?
          ActiveRecord::Base.establish_connection(SimpleWorker.config.database)
        end
      end
    end

    def set_auto_attributes
      set_global_attributes
    end

    def set_global_attributes
      return unless SimpleWorker.config
      ga = SimpleWorker.config.global_attributes
      if ga && ga.size > 0
        ga.each_pair do |k, v|
#                    puts "k=#{k} v=#{v}"
          if self.respond_to?(k)
            self.send("#{k}=", v)
          end
        end
      end
    end

    # Call this to queue up your job to SimpleWorker cloud.
    # options:
    #   :priority => 0,1 or 2. Default is 0.
    #   :recursive => true/false. Default is false. If you queue up a worker that is the same class as the currently
    #                 running worker, it will be rejected unless you set this explicitly so we know you meant to do it.
    def queue(options={})
#            puts 'in queue'
      set_auto_attributes
      upload_if_needed

      response = SimpleWorker.service.queue(self.class.name, sw_get_data, options)
#            puts 'queue response=' + response.inspect
#      @task_set_id = response["task_set_id"]
      @task_id = response["task_id"]
      response
    end

    def status
      SimpleWorker.service.status(task_id)
    end

    # will return after job has completed or errored out.
    # Returns status.
    # todo: add a :timeout option
    def wait_until_complete
      tries = 0
      status = nil
      sleep 1
      while tries < 100
        status = self.status
        puts "Waiting... status=" + status["status"]
        if status["status"] != "queued" && status["status"] != "running"
          break
        end
        sleep 2
      end
      status
    end


    def upload
      upload_if_needed
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
    def schedule(schedule)
      set_global_attributes
      upload_if_needed

      response = SimpleWorker.service.schedule(self.class.name, sw_get_data, schedule)
#            puts 'schedule response=' + response.inspect
      @schedule_id = response["schedule_id"]
      response
    end

    def schedule_status
      SimpleWorker.service.schedule_status(schedule_id)
    end

    # Retrieves the log for this worker from the SimpleWorker service.
    def get_log
      SimpleWorker.service.log(task_id)
    end

    # Callbacks for developer
    def before_upload

    end

    def after_upload

    end

    def before_run

    end

    def after_run

    end

    private

    def upload_if_needed

      before_upload

#      puts 'upload_if_needed ' + self.class.name
      # Todo, watch for this file changing or something so we can reupload (if in dev env)
      unless uploaded?
        merged = self.class.instance_variable_get(:@merged)
        unmerged = self.class.instance_variable_get(:@unmerged)
        merged_gems = self.class.instance_variable_get(:@merged_gems)
#        puts 'merged1=' + merged.inspect

        subclass = self.class
        rfile = subclass.instance_variable_get(:@caller_file) # Base.caller_file # File.expand_path(Base.subclass)
#        puts 'subclass file=' + rfile.inspect
#        puts 'subclass.name=' + subclass.name
        superclass = subclass
        # Also get merged from subclasses up to SimpleWorker::Base
        while (superclass = superclass.superclass)
#          puts 'superclass=' + superclass.name
          break if superclass.name == SimpleWorker::Base.name
          super_merged = superclass.instance_variable_get(:@merged)
#                     puts 'merging caller file: ' + superclass.instance_variable_get(:@caller_file).inspect
          super_merged << superclass.instance_variable_get(:@caller_file)
          merged = super_merged + merged
#          puts 'merged with superclass=' + merged.inspect
        end
        merged += SimpleWorker.config.models if SimpleWorker.config.models
        SimpleWorker.service.upload(rfile, subclass.name, :merge=>merged, :unmerge=>unmerged, :merged_gems=>merged_gems)
        self.class.instance_variable_set(:@uploaded, true)
      else
        SimpleWorker.logger.debug 'Already uploaded for ' + self.class.name
      end
      merged_workers = self.class.instance_variable_get(:@merged_workers)
      if merged_workers.size > 0
#        puts 'now uploading merged workers ' + merged_workers.inspect
        merged_workers.each do |mw|
          # to support merges in the secondary worker, we should instantiate it here, then call "upload"
          SimpleWorker.logger.debug 'Instantiating and uploading ' + mw[1]
          Kernel.const_get(mw[1]).new.upload
#                    SimpleWorker.service.upload(mw[0], mw[1])
        end
      end

      after_upload
    end

    def sw_get_data
      data = {}

      payload = {}
      self.instance_variables.each do |iv|
        payload[iv] = instance_variable_get(iv)
      end
      data[:attr_encoded] = Base64.encode64(payload.to_json)
      data[:file_name] = File.basename(self.class.instance_variable_get(:@caller_file))

      config_data = SimpleWorker.config.get_atts_to_send
      data[:sw_config] = config_data
      return data
    end


  end
end
