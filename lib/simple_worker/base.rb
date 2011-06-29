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
      @merged_mailers = []
      @merged_folders = {}
      @unmerged = []
      @unmerged_gems = []

      def reset!
        @merged = []
        @merged_workers = []
        @merged_gems = []
        @merged_mailers = []
        @merged_folders = {}
        @unmerged = []
        @unmerged_gems = []
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
#          puts 'f2=' + f2
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
      def merge_gem(gem_name, options=nil)
        gem_info = {:name=>gem_name, :merge=>true}
        if options.is_a?(Hash)
          gem_info.merge!(options)
        else
          gem_info[:version] = options
        end
        path = SimpleWorker::Service.get_gem_path(spec)
        if !path
          raise "Gem path not found for #{gem_name}"
        end
        gem_info[:path] = path
        @merged_gems << gem_info
        require options[:require] || gem_name
      end


      def unmerge_gem(gem_name)
        gem_info = {:name=>gem_name}
        @unmerged_gems << gem_info
      end

        #merge action_mailer mailers
      def merge_mailer(mailer, params={})
        check_for_file mailer
        basename = File.basename(mailer, File.extname(mailer))
        path_to_templates = params[:path_to_templates] || File.join(Rails.root, "app/views/#{basename}")
        @merged_mailers << {:name=>basename, :path_to_templates=>path_to_templates, :filename => mailer}.merge!(params)
      end

      def merge_folder(path)
        files = []
        Dir["#{path}*.rb"].each do |f|
          f = check_for_file(f)
          files<<f
        end
        @merged_folders[path]=files unless files.empty?
        SimpleWorker.logger.info "Merged folders! #{@merged_folders.inspect}"
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

    def enqueue(options={})
      queue(options)
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
      check_service
      if task_id
        task_status
      elsif schedule_id
        schedule_status
      else
        raise "Queue or schedule before check status."
      end
    end

    def task_status
      SimpleWorker.service.status(task_id)
    end

    def is_local?
      !is_remote?
    end

    def is_remote?
      false
    end

      # will return after job has completed or errored out.
      # Returns status.
      # todo: add a :timeout option
    def wait_until_complete
      check_service
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

    def gems_to_merge(merged_gems)
      list_of_gems =[]
      if merged_gems && merged_gems.size > 0
        installed_gems = SimpleWorker.config.get_server_gems
        merged_gems.each do |gem|
          gem.merge!({:merge=>(!installed_gems.find { |g| g["name"]==gem[:name] && g["version"]==gem[:version] })})
          list_of_gems<< gem if (list_of_gems.select { |g| g[:name]==gem[:name] }).empty?
        end
        SimpleWorker.logger.debug "#{list_of_gems.inspect}"
      end
      list_of_gems
    end

    def check_service
      raise "SimpleWorker configuration not set." unless SimpleWorker.service
    end

    def self.extract_superclasses_merges(worker, merged)
      subclass = worker.class
      rfile = subclass.instance_variable_get(:@caller_file) # Base.caller_file # File.expand_path(Base.subclass)
                                                            #        puts 'subclass file=' + rfile.inspect
                                                            #        puts 'subclass.name=' + subclass.name
      superclass = subclass
                                                            # Also get merged from subclasses up to SimpleWorker::Base
      while (superclass = superclass.superclass)
        #puts 'superclass=' + superclass.name
        break if superclass.name == SimpleWorker::Base.name
        super_merged = superclass.instance_variable_get(:@merged)
          #puts 'merging caller file: ' + superclass.instance_variable_get(:@caller_file).inspect
        super_merged << superclass.instance_variable_get(:@caller_file)
        merged = super_merged + merged
        #puts 'merged with superclass=' + merged.inspect
      end
      return merged, rfile, subclass
    end

    def self.extract_merged_workers(worker)
      merged_workers = worker.class.instance_variable_get(:@merged_workers)
      SimpleWorker.logger.debug "Looking for merged_workers in #{worker.class.name}: #{merged_workers.inspect}"
      ret = []
      if merged_workers && merged_workers.size > 0
        merged_workers.each do |mw|
          SimpleWorker.logger.debug "merged worker found in #{worker.class.name}: #{mw.inspect}"
          ret << mw[0]
        end
      end
      ret
    end

    def upload_if_needed
      check_service
      SimpleWorker.service.check_config

      before_upload

      merged = self.class.instance_variable_get(:@merged)

        # do merged_workers first because we need to get their subclasses and what not too
      merged_workers = self.class.instance_variable_get(:@merged_workers)
      if merged_workers && merged_workers.size > 0
        SimpleWorker.logger.debug 'now uploading merged workers ' + merged_workers.inspect
        merged_workers.each do |mw|
          SimpleWorker.logger.debug 'Instantiating and uploading ' + mw[1]
          mw_instantiated = Kernel.const_get(mw[1]).new
          mw_instantiated.upload

          merged, rfile, subclass = SimpleWorker::Base.extract_superclasses_merges(mw_instantiated, merged)
          merged += SimpleWorker::Base.extract_merged_workers(mw_instantiated)

        end
      end

#      puts 'upload_if_needed ' + self.class.name
# Todo, watch for this file changing or something so we can reupload (if in dev env)
      unless uploaded?
        unmerged = self.class.instance_variable_get(:@unmerged)
        merged_gems = self.class.instance_variable_get(:@merged_gems)
        merged_mailers = self.class.instance_variable_get(:@merged_mailers)
        merged_folders = self.class.instance_variable_get(:@merged_folders)
#        puts 'merged1=' + merged.inspect

        merged, rfile, subclass = SimpleWorker::Base.extract_superclasses_merges(self, merged)
        if SimpleWorker.config.auto_merge
          puts "Auto merge Enabled"
          merged += SimpleWorker.config.models if SimpleWorker.config.models
          merged_mailers += SimpleWorker.config.mailers if SimpleWorker.config.mailers
          SimpleWorker.config.gems.each do |gem|
            merged_gems<<gem
          end
        end
        unless merged_gems.empty?
          merged_gems = gems_to_merge(merged_gems)
          merged_gems.uniq!
        end
        merged.uniq!
        merged_mailers.uniq!
        SimpleWorker.service.upload(rfile, subclass.name, :merge=>merged, :unmerge=>unmerged, :merged_gems=>merged_gems, :merged_mailers=>merged_mailers, :merged_folders=>merged_folders)
        self.class.instance_variable_set(:@uploaded, true)
      else
        SimpleWorker.logger.debug 'Already uploaded for ' + self.class.name
      end


      after_upload
    end

    def sw_get_data
      data = {}

      payload = {}
        # todo: should put these down a layer, eg: payload[:attributes]
      self.instance_variables.each do |iv|
        payload[iv] = instance_variable_get(iv)
      end
      data[:attr_encoded] = Base64.encode64(payload.to_json)
      data[:file_name] = File.basename(self.class.instance_variable_get(:@caller_file))
      if defined?(Rails)
        data[:rails] = {}
        data[:rails]['env'] = Rails.env
      end

      config_data = SimpleWorker.config.get_atts_to_send
      data[:sw_config] = config_data
      return data
    end


  end
end
