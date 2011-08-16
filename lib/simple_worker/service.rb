require 'base64'
require 'logger'
require 'zip'
require 'rest_client'
require 'json'

require_relative 'api'

module SimpleWorker

  class Service < SimpleWorker::Api::Client

    attr_accessor :config

    def initialize(access_key, secret_key, options={})
      if options[:config]
        self.config = options[:config]
      else
        c = SimpleWorker::Config.new unless self.config
        c.access_key = access_key
        c.secret_key = secret_key
        self.config = c
      end
      super("http://api.simpleworker.com/api/", access_key, secret_key, options)
      self.host = self.config.host if self.config && self.config.host
      SimpleWorker.logger.info 'SimpleWorker initialized.'
    end

    # Options:
    #    - :callback_url
    #    - :merge => array of files to merge in with this file
    def upload(filename, class_name, options={})
      name = options[:name] || class_name
#      puts "Uploading #{class_name}"
# check whether it should upload again
      tmp = Dir.tmpdir()
      md5file = "simple_worker_#{class_name.gsub("::", ".")}_#{access_key[0, 8]}.md5"
      existing_md5 = nil
      f = File.join(tmp, md5file)
      if File.exists?(f)
        existing_md5 = IO.read(f)
      end
# Check for code changes.
      md5 = Digest::MD5.hexdigest(File.read(filename))
      new_code = false
      if md5 != existing_md5
        SimpleWorker.logger.info "Uploading #{class_name}, code modified."
        File.open(f, 'w') { |f| f.write(md5) }
        new_code = true
        # todo: delete md5 file if error occurs during upload process
      else
#        puts "#{class_name}: same code, not uploading"
        return
      end

      zip_filename = build_merged_file(filename, options[:merge], options[:unmerge], options[:merged_gems], options[:merged_mailers], options[:merged_folders])
      SimpleWorker.logger.info 'file size to upload: ' + File.size(zip_filename).to_s

      if new_code
        options = {
            "class_name"=>class_name,
            "name"=>name,
            "standalone"=>true,
            "file_name"=> "runner.rb" # File.basename(filename)
        }
        #puts 'options for upload=' + options.inspect
        SimpleWorker.logger.info "Uploading now..."
        ret = post_file("code/put", File.new(zip_filename), options)
        SimpleWorker.logger.info "Done uploading."
        ret
      end
    end

    def get_server_gems
      hash = get("gems/list")
      JSON.parse(hash["gems"])
    end

    def logger
      SimpleWorker.logger
    end

    def self.get_gem_path(gem_info)
#      gem_name =(gem_info[:require] || gem_info[:name].match(/^[a-zA-Z0-9\-_]+/)[0])
      gem_name =(gem_info[:name].match(/^[a-zA-Z0-9\-_]+/)[0])
      #puts "Searching for #{gem_name}..."
      gems= Gem::Specification.respond_to?(:each) ? Gem::Specification.find_all_by_name(gem_name) : Gem::GemPathSearcher.new.find_all(gem_name)
      #      gems     = searcher.init_gemspecs.select { |gem| gem.name==gem_name }
      logger.debug 'gems found=' + gems.inspect
      gems = gems.select { |g| g.version.version==gem_info[:version] } if gem_info[:version]
      if !gems.empty?
        gem = gems.first
        gem.full_gem_path
      else
        SimpleWorker.logger.warn "Gem file was not found for #{gem_name}, continuing anyways."
        return nil
      end
    end

    def build_merged_file(filename, merged, unmerge, merged_gems, merged_mailers, merged_folders)

      merge = SimpleWorker.config.merged.dup
      merge.merge!(merged) if merged
      if unmerge
        unmerge.each_pair do |x, y|
          deleted = merge.delete x
          SimpleWorker.logger.debug "Unmerging #{x}. Success? #{deleted}"
        end
      end
      merged = merge
      puts 'merged=' + merged.inspect

      merged_gems = merged_gems.merge(SimpleWorker.config.merged_gems)
      puts 'merged_gems=' + merged_gems.inspect
      SimpleWorker.config.unmerged_gems.each_pair do |k, v|
        puts 'unmerging gem=' + k.inspect
        merged_gems.delete(k)
      end
      puts 'merged_gems_after=' + merged_gems.inspect

      merged_mailers ||= {}
      merged_mailers = merged_mailers.merge(SimpleWorker.config.mailers) if SimpleWorker.config.mailers

      #tmp_file = File.join(Dir.tmpdir(), File.basename(filename))
      tmp_file = File.join(Dir.tmpdir(), 'runner.rb')
      File.open(tmp_file, "w") do |f|
        # add some rails stuff if using Rails

        f.write("require 'simple_worker'\n")

        if defined?(Rails)
          f.write "module Rails
  def self.version
    '#{Rails.version}'
  end
  def self.env
    '#{Rails.env}'
  end
end
"
        end

        if merged_mailers && !merged_mailers.empty?
          # todo: isn't 'action_mailer already required in railtie?
          f.write "require 'action_mailer'\n"
          f.write "ActionMailer::Base.prepend_view_path('templates')\n"
        end
        #if SimpleWorker.config.auto_merge
        merged_gems.each_pair do |k, gem|
          puts "Bundling gem #{gem[:name]}..."
          if gem[:merge]
            f.write "$LOAD_PATH << File.join(File.dirname(__FILE__), '/gems/#{gem[:name]}/lib')\n"
          end
#              unless gem[:no_require]
          puts 'writing requires: ' + gem[:require].inspect
          if gem[:require].nil?
            gem[:require] = []
          elsif gem[:require].is_a?(String)
            gem[:require] = [gem[:require]]
          end
          puts gem[:require].inspect
          gem[:require].each do |r|
            #puts 'adding require to file ' + r.to_s
            f.write "require '#{r}'\n"
          end
#              end
        end

        if SimpleWorker.config.extra_requires
          SimpleWorker.config.extra_requires.each do |r|
            f.write "require '#{r}'\n"
          end
        end

        File.open(File.join(File.dirname(__FILE__), 'server', 'overrides.rb'), 'r') do |fr|
          while line = fr.gets
            f.write line
          end
        end

        merged.each_pair do |k, v|
          if v[:extname] == ".rb"
            f.write "require_relative '#{File.basename(v[:path])}'\n"
          end
        end
        merged_mailers.each_pair do |k, mailer|
          f.write "require_relative '#{mailer[:name]}'\n"
        end
        #end
        #f.write File.open(filename, 'r') { |mo| mo.read }
        f.write("require_relative '#{File.basename(filename)}'")

        File.open(File.join(File.dirname(__FILE__), "server", 'runner.rb'), 'r') do |fr|
          while line = fr.gets
            f.write line
          end
        end


      end
      #puts 'funner.rb=' + tmp_file
      merge['runner.rb'] = {:path=>tmp_file}
      #puts 'filename=' + filename
      merge[File.basename(filename)] = {:path=>filename}
      #puts "merge before uniq! " + merge.inspect      
      # puts "merge after uniq! " + merge.inspect

      fname2 = tmp_file + ".zip"
      #            puts 'fname2=' + fname2
      #            puts 'merged_file_array=' + merge.inspect
      #File.open(fname2, "w") do |f|
      File.delete(fname2) if File.exist?(fname2)
      Zip::ZipFile.open(fname2, 'w') do |f|
        if merged_gems && merged_gems.size > 0
          merged_gems.each_pair do |k, gem|
            next unless gem[:merge]
#            puts 'gem=' + gem.inspect
            path = gem[:path] # get_gem_path(gem)
            if path
              SimpleWorker.logger.debug "Collecting gem #{path}"
              Dir["#{path}/*", "#{path}/lib/**/**"].each do |file|
                # todo: could check if directory and it not lib, skip it
                SimpleWorker.logger.debug 'file for gem=' + file.inspect
#                puts 'gem2=' + gem.inspect
                zdest = "gems/#{gem[:name]}/#{file.sub(path+'/', '')}"
#                puts 'gem file=' + file.to_s
                SimpleWorker.logger.debug 'zip dest=' + zdest
                f.add(zdest, file)
              end
            else
              if gem[:auto_merged]
                # todo: should only continue if the gem was auto merged.
                SimpleWorker.logger.warn "Gem #{gem[:name]} #{gem[:version]} was not found, continuing anyways."
              else
                raise "Gem #{gem[:name]} #{gem[:version]} was not found, continuing anyways."
              end

            end
          end
        end
        if merged_folders && merged_folders.size > 0
          merged_folders.each do |folder, files|
            SimpleWorker.logger.debug "Collecting folder #{folder}"
            if files and files.size>0
              files.each do |file|
                zdest = "#{Digest::MD5.hexdigest(folder)}/#{file.sub(':', '_').sub('/', '_')}"
                SimpleWorker.logger.debug 'put file to=' + zdest
                f.add(zdest, file)
              end
            end
          end
        end

        puts "merge=" + merge.inspect
        merge.each_pair do |k, v|
          puts "merging k=#{k.inspect} v=#{v.inspect} into #{filename}"
          f.add(File.basename(v[:path]), v[:path])
        end
        if merged_mailers && merged_mailers.size > 0
          # puts " MERGED MAILERS" + merged_mailers.inspect
          merged_mailers.each_pair do |k, mailer|
            SimpleWorker.logger.debug "Collecting mailer #{mailer[:name]}"
            f.add(File.basename(mailer[:filename]), mailer[:filename])
            path = mailer[:path_to_templates]
            Dir["#{path}/**/**"].each do |file|
              zdest = "templates/#{mailer[:name]}/#{file.sub(path+'/', '')}"
              f.add(zdest, file)
            end
          end
        end
      end
      fname2
    end

    def add_sw_params(hash_to_send)
      # todo: remove secret key??  Can use worker service from within a worker without it now
      hash_to_send["sw_access_key"] = self.access_key
      hash_to_send["sw_secret_key"] = self.secret_key
      hash_to_send["api_version"] = SimpleWorker.api_version
    end

    def check_config
      if self.config.nil? || self.config.access_key.nil?
        raise "Invalid SimpleWorker configuration, no access key specified."
      end
    end

    def enqueue(class_name, data={}, options={})
      queue(class_name, data, options)
    end

    # class_name: The class name of a previously upload class, eg: MySuperWorker
    # data: Arbitrary hash of your own data that your task will need to run.
    def queue(class_name, data={}, options={})
      puts "Queuing #{class_name}..."
      check_config
      if !data.is_a?(Array)
        data = [data]
      end
      data.each do |d|
        d['class_name'] = class_name
        d['access_key'] = class_name
      end
      name = options[:name] || class_name
      hash_to_send = {}
      hash_to_send["payload"] = data
      hash_to_send["class_name"] = class_name
      hash_to_send["name"] = name
      #hash_to_send["standalone"] = true # new school
      hash_to_send["priority"] = options[:priority] if options[:priority]
      hash_to_send["options"] = options
      add_sw_params(hash_to_send)
      if defined?(RAILS_ENV)
        # todo: REMOVE THIS
        hash_to_send["rails_env"] = RAILS_ENV
      end
      return queue_raw(class_name, hash_to_send)

    end

    def queue_raw(class_name, data={})
      params = nil
      hash_to_send = data
      hash_to_send["class_name"] = class_name unless hash_to_send["class_name"]
      hash_to_send["name"] = class_name unless hash_to_send["name"]
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
      puts "Scheduling #{class_name}..."
      raise "Schedule must be a hash." if !schedule.is_a? Hash
#            if !data.is_a?(Array)
#                data = [data]
#            end
      hash_to_send = {}
      hash_to_send["payload"] = data
      hash_to_send["class_name"] = class_name
      hash_to_send["schedule"] = schedule
      add_sw_params(hash_to_send)
#            puts ' about to send ' + hash_to_send.inspect
      ret = post("scheduler/schedule", hash_to_send)
      ret
    end

    def cancel_schedule(scheduled_task_id)
      raise "Must include a schedule id." if scheduled_task_id.blank?
      hash_to_send = {}
      hash_to_send["schedule_id"] = scheduled_task_id
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

    def schedule_status(schedule_id)
      data = {"schedule_id"=>schedule_id}
      ret = get("scheduler/status", data)
      ret
    end

    # data is a hash, should include 'percent' and 'message'
    def set_progress(task_id, data)
      data={"data"=>data, "task_id"=>task_id}
      post("task/setstatus", data)
    end

    def log(task_id)
      data = {"task_id"=>task_id}
      ret = get("task/log", data, {:parse=>false})
#            puts ' ret=' + ret.inspect
#            ret["log"] = Base64.decode64(ret["log"])
      ret
    end


  end

end
