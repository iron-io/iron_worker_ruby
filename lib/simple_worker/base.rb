# This is an abstract module that developers creating works can mixin/include to use the SimpleWorker special functions.

require 'digest/md5'

module SimpleWorker

  class Base

    attr_accessor :task_set_id, :task_id, :schedule_id

    class << self
      attr_accessor :subclass, :caller_file
      @merged         = []
      @merged_workers = []
      @unmerged       = []

      def reset!
        @merged         = []
        @merged_workers = []
        @unmerged       = []
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
#                puts 'caller_file=' + caller_file
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
            f      = f2
          end
        end
        unless exists
          raise "File not found: " + f
        end
        f = File.expand_path(f)
        require f
        f
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

      def merge_worker(file, class_name)
        puts 'merge_worker in ' + self.name
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
#            puts 'run_local'
      set_auto_attributes
      run
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

    # Will send in all instance_variables.
    def queue
#            puts 'in queue'
      set_auto_attributes
      upload_if_needed

      response     = SimpleWorker.service.queue(self.class.name, sw_get_data)
#            puts 'queue response=' + response.inspect
      @task_set_id = response["task_set_id"]
      @task_id     = response["tasks"][0]["task_id"]
      response
    end

    def status
      SimpleWorker.service.status(task_id)
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

      response     = SimpleWorker.service.schedule(self.class.name, sw_get_data, schedule)
#            puts 'schedule response=' + response.inspect
      @schedule_id = response["schedule_id"]
      response
    end

    def schedule_status
      SimpleWorker.service.schedule_status(schedule_id)
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

      puts 'upload_if_needed ' + self.class.name
      # Todo, watch for this file changing or something so we can reupload
      unless uploaded?
        merged     = self.class.instance_variable_get(:@merged)
        unmerged     = self.class.instance_variable_get(:@unmerged)
#        puts 'merged1=' + merged.inspect

        subclass   = self.class
        rfile      = subclass.instance_variable_get(:@caller_file) # Base.caller_file # File.expand_path(Base.subclass)
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
        SimpleWorker.service.upload(rfile, subclass.name, :merge=>merged, :unmerge=>unmerged)
        self.class.instance_variable_set(:@uploaded, true)
      else
        puts 'already uploaded for ' + self.class.name
      end
      merged_workers = self.class.instance_variable_get(:@merged_workers)
      if merged_workers.size > 0
        puts 'now uploading merged workers ' + merged_workers.inspect
        merged_workers.each do |mw|
          # to support merges in the secondary worker, we should instantiate it here, then call "upload"
          puts 'instantiating and uploading ' + mw[1]
          Kernel.const_get(mw[1]).new.upload
#                    SimpleWorker.service.upload(mw[0], mw[1])
        end
      end

      after_upload
    end

    def sw_get_data
      data = {}
      self.instance_variables.each do |iv|
        data[iv] = instance_variable_get(iv)
      end

      config_data      = SimpleWorker.config.get_atts_to_send
      data[:sw_config] = config_data
      return data
    end


  end
end
