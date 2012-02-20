require 'digest/md5'
require 'base64'

module IronWorker

  class Base

    attr_accessor :task_set_id, :task_id, :schedule_id
    attr_reader :response

    class << self
      attr_accessor :subclass, :caller_file
      @merged = {}
      @merged_workers = {}
      @merged_gems = {}
      @merged_mailers = {}
      @merged_folders = {}
      @unmerged = {}
      @unmerged_gems = {}

      def reset!
        @merged = {}
        @merged_workers = {}
        @merged_gems = {}
        @merged_mailers = {}
        @merged_folders = {}
        @unmerged = {}
        @unmerged_gems = {}
      end

      def inherited(subclass)
        subclass.reset!

        caller_file = caller[0][0...(caller[0].index(":in"))]
        caller_file = caller_file[0...(caller_file.rindex(":"))]
        subclass.instance_variable_set(:@caller_file, caller_file)

        super
      end

      # merges the specified gem.
      def merge_gem(gem_name, options={})
        gem_info = IronWorker::MergeHelper.create_gem_info(gem_name, options)
        @merged_gems[gem_name.to_s] = gem_info
        reqs = gem_info[:require].is_a?(Array) ? gem_info[:require] : [gem_info[:require]]
        reqs.each do |r|
          r2 = "#{gem_info[:path]}/lib/#{r}"
          begin
            IronWorker.logger.debug 'requiring ' + r2
            require r2
          rescue LoadError=>ex
            IronWorker.logger.error "Error requiring gem #{r}: #{ex.message}"
            raise "Gem #{gem_name} was found, but we could not load the file '#{r2}'. You may need to use :require=>x.........."
          end
        end
      end


      def unmerge_gem(gem_name)
        #gem_info = {:name=>gem_name}
        #@unmerged_gems[gem_name.to_s] = gem_info
        gs = gem_name.to_s
        gem_info = {:name=>gs}
        @unmerged_gems[gs] = gem_info
        @merged_gems.delete(gs)
      end

      #merge action_mailer mailers
      def merge_mailer(mailer, params={})
        f2 = IronWorker::MergeHelper.check_for_file(mailer, @caller_file)
        basename = File.basename(mailer, f2[:extname])
        path_to_templates = params[:path_to_templates] || File.join(Rails.root, "app/views/#{basename}")
        @merged_mailers[basename] = {:name=>basename, :path_to_templates=>path_to_templates, :filename => f2[:path]}.merge!(params)
      end

      def merge_folder(path)
        files = []
        #puts "caller_file=" + caller_file
        if path[0, 1] == '/'
          abs_dir = path
        else # relative
          abs_dir = File.join(File.dirname(caller_file), path)
        end
        #puts 'abs_dir=' + abs_dir
        raise "Folder not found for merge_folder #{path}!" unless File.directory?(abs_dir)
        rbfiles = File.join(abs_dir, "*.rb")
        Dir[rbfiles].each do |f|
          #f2 = check_for_file(f)
          #puts "f2=#{f2}"
          merge(f)
          #files << f
          #@merged[f]
        end
        #@merged_folders[path] = files unless files.empty?
        #IronWorker.logger.info "Merged folders! #{@merged_folders.inspect}"
      end

      # merges the specified file.
      #
      # Example: merge 'models/my_model'
      def merge(f)
        f2 = IronWorker::MergeHelper.check_for_file(f, @caller_file)
        fbase = f2[:basename]
        ret = f2
        @merged[fbase] = ret
        ret
      end

      # Opposite of merge, this will omit the files you specify from being merged in. Useful in Rails apps
      # where a lot of things are auto-merged by default like your models.
      def unmerge(f)
        f2 = IronWorker::MergeHelper.check_for_file(f, @caller_file)
        fbase = f2[:basename]
        @unmerged[fbase] = f2
        @merged.delete(fbase)
      end


      # Use this to merge in other workers. These are treated differently the normal merged files because
      # they will be uploaded separately and treated as distinctly separate workers.
      #
      # @param file [String] This is the path to the file, just like merge.
      # @param class_name [String|Class] 'MyWorker' or just MyWorker.
      # @return [Hash]
      def merge_worker(file, class_name)
        ret = merge(file)
        ret[:class_name] = case class_name
                             when String
                               class_name.strip
                             when Class
                               class_name.name
                             else
                               IronWorker.service.logger.warn "merge_worker: only String or Class is expected as class_name"
                               class_name # probably user does know what is he doing
                           end
        @merged_workers[file] = ret
        ret
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
      init_mailer
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

    def init_mailer
      if IronWorker.config.mailer
        require 'action_mailer'
        ActionMailer::Base.raise_delivery_errors = true
        ActionMailer::Base.smtp_settings = (IronWorker.config.mailer)
      end
    end

    def init_database
      if IronWorker.config.database
        require 'active_record'
        if !ActiveRecord::Base.connected?
          ActiveRecord::Base.establish_connection(IronWorker.config.database)
        end
      end
    end

    def set_auto_attributes
      set_global_attributes
    end

    def set_global_attributes
      return unless IronWorker.config
      ga = IronWorker.config.global_attributes
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

    # Call this to queue up your job to IronWorker cloud.
    # options:
    #   :priority => 0, 1 or 2. Default is 0.
    #   :recursive => true/false. Default is false. If you queue up a worker that is the same class as the currently
    #                 running worker, it will be rejected unless you set this explicitly so we know you meant to do it.
    def queue(options={})
#            puts 'in queue'

      IronWorker.config.force_upload = IronWorker.config.force_upload && is_local?
      set_auto_attributes
      upload_if_needed(options)
      response = IronWorker.service.queue(self.class.name, sw_get_data, options)
      IronWorker.service.logger.debug 'queue response=' + response.inspect
      @response = response
      @task_id = response["tasks"][0]["id"]
      response
    end

    # Receive the status of your worker.
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
      IronWorker.service.status(task_id)
    end

    def is_local?
      IronWorker.is_local?
    end

    def is_remote?
      IronWorker.is_remote?
    end

    # will return after job has completed or errored out.
    # Returns status.
    # todo: add a :timeout option
    def wait_until_complete
      check_service
      IronWorker.service.wait_until_complete(self.task_id)
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
    #     - name:          Provide a name for the schedule, defaults to class name. Use this if you want more than one schedule per worker class.
    #
    def schedule(schedule)
      set_global_attributes
      upload_if_needed(schedule)

      response = IronWorker.service.schedule(self.class.name, sw_get_data, schedule)
      IronWorker.service.logger.debug 'schedule response=' + response.inspect
      @schedule_id = response["schedules"][0]["id"]
      response
    end

    def schedule_status
      IronWorker.service.schedule_status(schedule_id)
    end

    # Retrieves the log for this worker from the IronWorker service.
    def get_log(options={})
      IronWorker.service.log(task_id, options)
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
      list_of_gems = {}
      if merged_gems && merged_gems.size > 0
        installed_gems = IronWorker.config.get_server_gems
        merged_gems.each_pair do |k, gem|
          gem.merge!({:merge=>(!installed_gems.find { |g| g["name"]==gem[:name] && g["version"]==gem[:version] })})
          list_of_gems[gem[:name]] = gem # don't' need this if (list_of_gems.select { |k,g| g[:name]==gem[:name] }).empty?
        end
        IronWorker.logger.debug "#{list_of_gems.inspect}"
      end
      list_of_gems
    end

    def check_service
      raise "IronWorker configuration not set." unless IronWorker.service
    end

    def self.extract_superclasses_merges(worker, merged)
      subclass = worker.class
      rfile = subclass.instance_variable_get(:@caller_file) # Base.caller_file # File.expand_path(Base.subclass)
                                                            #        puts 'subclass file=' + rfile.inspect
                                                            #        puts 'subclass.name=' + subclass.name
      superclass = subclass
                                                            # Also get merged from subclasses up to IronWorker::Base
      while (superclass = superclass.superclass)
        #puts 'superclass=' + superclass.name
        break if superclass.name == IronWorker::Base.name
        super_merged = superclass.instance_variable_get(:@merged)
        #puts 'merging caller file: ' + superclass.instance_variable_get(:@caller_file).inspect
        caller_to_add = superclass.instance_variable_get(:@caller_file)
        fb = File.basename(caller_to_add)
        r = {:name=>fb, :path=>caller_to_add}
        super_merged[fb] = r
        merged.merge!(super_merged)
        #puts 'merged with superclass=' + merged.inspect
      end
      return merged, rfile, subclass
    end

    def self.extract_merged_workers(worker)
      merged_workers = worker.class.instance_variable_get(:@merged_workers)
      IronWorker.logger.debug "Looking for merged_workers in #{worker.class.name}: #{merged_workers.inspect}"
      ret = {}
      if merged_workers && merged_workers.size > 0
        merged_workers.each_pair do |k, mw|
          IronWorker.logger.debug "merged worker found in #{worker.class.name}: #{mw.inspect}"
          ret[mw[:name]] = mw
        end
      end
      ret
    end

    def upload_if_needed(options={})
      return if is_remote?
      check_service
      IronWorker.service.check_config

      before_upload

      merged = self.class.instance_variable_get(:@merged)

      # do merged_workers first because we need to get their subclasses and what not too
      merged_workers = self.class.instance_variable_get(:@merged_workers)
      if merged_workers && merged_workers.size > 0
        IronWorker.logger.debug 'now uploading merged workers ' + merged_workers.inspect
        merged_workers.each_pair do |mw, v|
          IronWorker.logger.debug 'Instantiating and uploading ' + v.inspect
          mw_instantiated = Kernel.const_get(v[:class_name]).new
          mw_instantiated.upload

          merged, rfile, subclass = IronWorker::Base.extract_superclasses_merges(mw_instantiated, merged)
          merged.merge!(IronWorker::Base.extract_merged_workers(mw_instantiated))

        end
      end

      if !uploaded?
        unmerged = self.class.instance_variable_get(:@unmerged)
        merged_gems = self.class.instance_variable_get(:@merged_gems)
        unmerged_gems = self.class.instance_variable_get(:@unmerged_gems)
        merged_mailers = self.class.instance_variable_get(:@merged_mailers)
        merged_folders = self.class.instance_variable_get(:@merged_folders)
        merged, rfile, subclass = IronWorker::Base.extract_superclasses_merges(self, merged)
        merged_mailers = merged_mailers.merge(IronWorker.config.mailers) if IronWorker.config.mailers
        unless merged_gems.size == 0
          merged_gems = gems_to_merge(merged_gems)
        end

        options_for_upload = {:merge=>merged, :unmerge=>unmerged, :merged_gems=>merged_gems, :unmerged_gems=>unmerged_gems, :merged_mailers=>merged_mailers, :merged_folders=>merged_folders}
        options_for_upload.merge!(options)
        IronWorker.service.upload(rfile, subclass.name, options_for_upload)
        self.class.instance_variable_set(:@uploaded, true)
      else
        IronWorker.logger.debug 'Already uploaded for ' + self.class.name
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
      data['class_name'] = self.class.name
      data[:attr_encoded] = Base64.encode64(payload.to_json)
      data[:file_name] = File.basename(self.class.instance_variable_get(:@caller_file))
      if defined?(Rails)
        data[:rails] = {}
        data[:rails]['env'] = Rails.env
        data[:rails]['version'] = Rails.version
      end
      config_data = IronWorker.config.get_atts_to_send
      data[:sw_config] = config_data
      return data
    end


  end
end
