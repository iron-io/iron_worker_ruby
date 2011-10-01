# This is used when a bad worker is uploaded.

module SimpleWorker

  class InvalidWorkerError < StandardError; end

  class << self
    def running_class=(rc)
      @running_class = rc
    end
    def running_class
      @running_class
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


  class Base

    class << self

      def merge(*files)
        #files.each do |file|
        #  file = file.to_s
        #  unless file.end_with?(".rb")
        #    file << ".rb"
        #  end
        #  #puts 'code_dir=' + code_dir.inspect
        #  filename = File.join(code_dir, File.basename(file))
        #  #puts "merge #{filename}"
        #  #puts "FILENAME #{filename}"
        #  require filename if File.exist?(filename) # for backwards compatability
        #end

      end


      def merge_folder(path)
        #puts "PATH=#{path}"
        #puts "#{code_dir}/#{Digest::MD5.hexdigest(path)}/**/*.rb"
        #Dir["#{code_dir}/#{Digest::MD5.hexdigest(path)}/**/*.rb"].each do |f|
        #  puts "requiring #{f.inspect}"
        #  require f if File.exist?(f)
        #end
      end

      def unmerge(*files)
        # ignore this here
      end

      def merge_mailer(mailer, params=nil)
        #merge(mailer)
      end

      def merge_gem(gem, version=nil)
        #gem_info = {:name=>gem}
        #if version.is_a?(Hash)
        #  gem_info.merge!(version)
        #else
        #  gem_info[:version] = version
        #end
        #gem_name =(gem.match(/^[a-zA-Z0-9\-_]+/)[0])
        #$LOAD_PATH << File.join(code_dir, "/gems/#{gem_name}") #backwards compatibility, should be removed later
        #$LOAD_PATH << File.join(code_dir, "/gems/#{gem_name}/lib")
        #                                                       # what's the diff here? This one seems more common: $:.unshift File.join(File.dirname(__FILE__), "/gems/#{gem_name}")
        #                                                       #puts 'gem_info = ' + gem_info.inspect
        #require gem_info[:require] || gem_name
      end

      def merge_worker(file, class_name)

      end

    end

    def is_remote?
      true
    end

    #:todo remove this method later, when new simple_worker gem will be released
    def is_local?
      !is_remote?
    end

    def log(str)
      puts str.to_s
    end

    def set_progress(hash)
      SimpleWorker.service.set_progress(@job_data["task_id"], hash)
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
      if SimpleWorker.queueing_enabled? && (!same_clazz? || options[:recursive])
        orig_queue(options)
#        data = sw_get_data()
#        queue_other(self.class.name, data)
      else
        log (SimpleWorker.queueing_enabled? ? "WARNING: Recursion detected in queueing, pass in :recursive=>true to bypass this." : "Queuing disabled while loading.")
      end
    end

    def schedule(schedule)
      if SimpleWorker.queueing_enabled? && (!same_clazz? || schedule[:recursive])
        orig_schedule(schedule)
#        data = sw_get_data()
#        schedule_other(self.class.name, data, schedule)
      else
        log (SimpleWorker.queueing_enabled? ? "WARNING: Recursion detected in scheduling." : "Scheduling disabled while loading.")
      end

    end

    def status
      if SimpleWorker.queueing_enabled?
        orig_status
      else
        log "Status disabled while loading."
      end
    end

    def same_clazz?
      SimpleWorker.running_class == self.class
    end

  end


  class Service < SimpleWorker::Api::Client
    def upload(filename, class_name, options={})
      #puts "Skipping upload, We don't upload from run.rb!"
      # don't upload, should already be here.
    end

    def add_sw_params(hash_to_send)
      hash_to_send["token"] = self.config.token
      hash_to_send["project_id"] = self.config.project_id
      hash_to_send["api_version"] = SimpleWorker.api_version
    end
  end


  module UsedInWorker
    def log(str)
      puts str.to_s
    end
  end


end
