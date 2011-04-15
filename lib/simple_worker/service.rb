require 'base64'
require 'logger'
require 'appoxy_api'
require 'zip'
module SimpleWorker

  @@logger       = Logger.new(STDOUT)
  @@logger.level = Logger::INFO

  def self.logger
    @@logger
  end

  def self.api_version
    3
  end

  class Service < Appoxy::Api::Client

    attr_accessor :config

    def initialize(access_key, secret_key, options={})
      SimpleWorker.logger.info 'Starting SimpleWorker::Service...'
      if options[:config]
        self.config = options[:config]
      else
        c = SimpleWorker::Config.new unless self.config
        c.access_key = access_key
        c.secret_key = secret_key
        self.config  = c
      end
      super("http://api.simpleworker.com/api/", access_key, secret_key, options)
      self.host = self.config.host if self.config && self.config.host
    end

    # Options:
    #    - :callback_url
    #    - :merge => array of files to merge in with this file
    def upload(filename, class_name, options={})
#      puts "Uploading #{class_name}"
      # check whether it should upload again
      tmp          = Dir.tmpdir()
      md5file      = "simple_worker_#{class_name.gsub("::", ".")}_#{access_key[0, 8]}.md5"
      existing_md5 = nil
      f            = File.join(tmp, md5file)
      if File.exists?(f)
        existing_md5 = IO.read(f)
      end
      # Check for code changes.
      md5      = Digest::MD5.hexdigest(File.read(filename))
      new_code = false
      if md5 != existing_md5
        SimpleWorker.logger.info "Uploading #{class_name}, code modified."
        File.open(f, 'w') { |f| f.write(md5) }
        new_code = true
      else
#        puts "#{class_name}: same code, not uploading"
        return
      end


      zip_filename = build_merged_file(filename, options[:merge], options[:unmerge], options[:merged_gems], options[:merged_mailers])

#            sys.classes[subclass].__file__
#            puts '__FILE__=' + Base.subclass.__file__.to_s
#            puts "new md5=" + md5


      if new_code
#        mystring = nil
#        file     = File.open(filename, "r") do |f|
#          mystring = f.read
#        end
#        mystring = Base64.encode64(mystring)
#        puts 'code=' + mystring
        options = {
                "class_name"=>class_name,
                "file_name" => File.basename(filename)
        }
        #puts 'options for upload=' + options.inspect
        ret     = post_file("code/put", File.new(zip_filename), options)
        ret
      end
    end

    def get_server_gems
      hash = get("gems/list")
      gems = JSON.parse(hash["gems"])
      puts "GEMS #{gems.inspect}"
      return gems
      #[{:name=>"rake", :version=>"0.8.7"}, {:name=>"sqlite3-ruby", :version=>"1.3.3"}, {:name=>"simple_worker", :version=>"0.5.8"}, {:name=>"abstract", :version=>"1.0.0"}, {:name=>"builder", :version=>"2.1.2"}, {:name=>"i18n", :version=>"0.5.0"}, {:name=>"activemodel", :version=>"3.0.5"}, {:name=>"erubis", :version=>"2.6.6"}, {:name=>"rack", :version=>"1.2.2"}, {:name=>"rack-mount", :version=>"0.6.14"}, {:name=>"rack-test", :version=>"0.5.7"}, {:name=>"tzinfo", :version=>"0.3.26"}, {:name=>"actionpack", :version=>"3.0.5"}, {:name=>"mime-types", :version=>"1.16"}, {:name=>"polyglot", :version=>"0.3.1"}, {:name=>"treetop", :version=>"1.4.9"}, {:name=>"mail", :version=>"2.2.15"}, {:name=>"actionmailer", :version=>"3.0.5"}, {:name=>"arel", :version=>"2.0.9"}, {:name=>"activerecord", :version=>"3.0.5"}, {:name=>"activeresource", :version=>"3.0.5"}, {:name=>"addressable", :version=>"2.2.5"}, {:name=>"rest-client", :version=>"1.6.1"}, {:name=>"appoxy_api", :version=>"0.0.11"}, {:name=>"hashie", :version=>"1.0.0"}, {:name=>"mini_fb", :version=>"1.1.7"}, {:name=>"oauth", :version=>"0.4.4"}, {:name=>"ruby-openid", :version=>"2.1.8"}, {:name=>"http_connection", :version=>"1.4.0"}, {:name=>"uuidtools", :version=>"2.1.2"}, {:name=>"xml-simple", :version=>"1.0.15"}, {:name=>"aws", :version=>"2.4.5"}, {:name=>"simple_record", :version=>"2.1.3"}, {:name=>"appoxy_rails", :version=>"0.0.33"}, {:name=>"bundler", :version=>"1.0.10"}, {:name=>"rspec-core", :version=>"2.5.1"}, {:name=>"diff-lcs", :version=>"1.1.2"}, {:name=>"rspec-expectations", :version=>"2.5.0"}, {:name=>"rspec-mocks", :version=>"2.5.0"}, {:name=>"rspec", :version=>"2.5.0"}, {:name=>"concur", :version=>"0.0.4"}, {:name=>"multipart-post", :version=>"1.1.0"}, {:name=>"faraday", :version=>"0.5.7"}, {:name=>"hominid", :version=>"3.0.2"}, {:name=>"hoptoad_notifier", :version=>"2.4.9"}, {:name=>"local_cache", :version=>"1.2.2"}, {:name=>"multi_json", :version=>"0.0.5"}, {:name=>"net-ldap", :version=>"0.1.1"}, {:name=>"net-ssh", :version=>"2.0.23"}, {:name=>"net-sftp", :version=>"2.0.5"}, {:name=>"nokogiri", :version=>"1.4.4"}, {:name=>"oa-core", :version=>"0.2.0"}, {:name=>"oa-basic", :version=>"0.2.0"}, {:name=>"pyu-ruby-sasl", :version=>"0.0.3.2"}, {:name=>"rubyntlm", :version=>"0.1.1"}, {:name=>"oa-enterprise", :version=>"0.2.0"}, {:name=>"oa-more", :version=>"0.2.0"}, {:name=>"oauth2", :version=>"0.1.1"}, {:name=>"oa-oauth", :version=>"0.2.0"}, {:name=>"rack-openid", :version=>"1.2.0"}, {:name=>"ruby-openid-apps-discovery", :version=>"1.2.0"}, {:name=>"oa-openid", :version=>"0.2.0"}, {:name=>"omniauth", :version=>"0.2.0"}, {:name=>"thor", :version=>"0.14.6"}, {:name=>"railties", :version=>"3.0.5"}, {:name=>"rails", :version=>"3.0.5"}, {:name=>"rails", :version=>"3.0.3"}, {:name=>"recaptcha", :version=>"0.3.1"}, {:name=>"zip", :version=>"2.0.2"}, {:name=>"simple_worker", :version=>"0.5.1"}, {:name=>"validatable", :version=>"1.6.7"}]
    end

    def get_gem_path(gem_info)
      gem_name =(gem_info[:require] || gem_info[:name].match(/^[a-zA-Z0-9\-_]+/)[0])
      puts "Searching for #{gem_name}..."
      searcher = Gem::GemPathSearcher.new
      gems = searcher.find_all(gem_name)
#      gems     = searcher.init_gemspecs.select { |gem| gem.name==gem_name }
      puts 'gems found=' + gems.inspect
      gems = gems.select { |g| g.version.version==gem_info[:version] } if gem_info[:version]
      if !gems.empty?
        gem = gems.first
        gem.full_gem_path + "/lib"
      else
        nil
      end
    end

    def build_merged_file(filename, merge, unmerge, merged_gems, merged_mailers)
#      unless (merge && merge.size > 0) || (merged_gems && merged_gems.size > 0)
#        return filename
#      end
      merge = merge.nil? ? [] : merge.dup
      if unmerge
        unmerge.each do |x|
          deleted = merge.delete x
#          puts "Unmerging #{x}. Success? #{deleted}"
        end
      end
      merge.uniq!
      tmp_file = File.join(Dir.tmpdir(), File.basename(filename))
      File.open(tmp_file, "w") do |f|
        if SimpleWorker.config.extra_requires
          SimpleWorker.config.extra_requires.each do |r|
            f.write "require '#{r}'\n"
          end
        end
        if merged_mailers
          f.write "require 'action_mailer'\n"
          f.write "ActionMailer::Base.prepend_view_path('templates')\n"
        end
        if SimpleWorker.config.auto_merge
          if SimpleWorker.config.gems
            SimpleWorker.config.gems.each do |gem|
              f.write "$LOAD_PATH << File.join(File.dirname(__FILE__), '/gems/#{gem[:name]}')\n" if gem[:merge]
              f.write "require '#{gem[:require]||gem[:name]}'\n"
            end
          end
          if SimpleWorker.config.models
            SimpleWorker.config.models.each do |model|
              f.write "require File.join(File.dirname(__FILE__),'#{File.basename(model)}')\n"
            end
          end
          if SimpleWorker.config.mailers
            SimpleWorker.config.mailers.each do |mailer|
              f.write "require File.join(File.dirname(__FILE__),'#{mailer[:name]}')\n"
            end
          end
        end
        f.write File.open(filename, 'r') { |mo| mo.read }
      end
      merge << tmp_file
      #puts "merge before uniq! " + merge.inspect      
      # puts "merge after uniq! " + merge.inspect

      fname2 = tmp_file + ".zip"
#            puts 'fname2=' + fname2
#            puts 'merged_file_array=' + merge.inspect
      #File.open(fname2, "w") do |f|
      File.delete(fname2) if File.exist?(fname2)
      Zip::ZipFile.open(fname2, 'w') do |f|
        if merged_gems
          merged_gems.uniq!
          merged_gems.each do |gem|
#            puts 'gem=' + gem.inspect
            path = get_gem_path(gem)
            if path
              puts "Collecting gem #{path}"
              Dir["#{path}/**/**"].each do |file|
#                puts 'gem2=' + gem.inspect
                zdest = "gems/#{gem[:name]}/#{file.sub(path+'/', '')}"
                puts 'gem file=' + file.to_s
                puts 'zdest=' + zdest
                f.add(zdest, file)
              end
            else
              raise "Gem #{gem[:name]} #{gem[:version]} was not found."
            end
          end
        end
        puts "merge gems - done"
        merge.each do |m|
          puts "merging #{m} into #{filename}"
          f.add(File.basename(m), m)
        end
        puts "merge models - done"
        if merged_mailers
          puts " MERGED MAILERS" + merged_mailers.inspect
          merged_mailers.each do |mailer|
            puts "Collecting mailer #{mailer[:name]}"
            f.add(File.basename(mailer[:filename]), mailer[:filename])
            path = mailer[:path_to_templates]
            Dir["#{path}/**/**"].each do |file|
              zdest = "templates/#{mailer[:name]}/#{file.sub(path+'/', '')}"
              f.add(zdest, file)
            end
          end
        end
        puts "merging templates - done"
      end
      fname2
    end

    def add_sw_params(hash_to_send)
      # todo: remove secret key??  Can use worker service from within a worker without it now
      hash_to_send["sw_access_key"] = self.access_key
      hash_to_send["sw_secret_key"] = self.secret_key
      hash_to_send["api_version"]   = SimpleWorker.api_version
    end

    def check_config
      if self.config.nil? || self.config.access_key.nil?
        raise "Invalid SimpleWorker configuration, no access key specified."
      end
    end

    # class_name: The class name of a previously upload class, eg: MySuperWorker
    # data: Arbitrary hash of your own data that your task will need to run.
    def queue(class_name, data={}, options={})
      puts "Queuing #{class_name}..."
      check_config
      if !data.is_a?(Array)
        data = [data]
      end
#      p data
      hash_to_send               = {}
      hash_to_send["payload"]    = data
      hash_to_send["class_name"] = class_name
      hash_to_send["priority"] = options[:priority] if options[:priority]
      hash_to_send["options"] = options
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
      puts "Scheduling #{class_name}..."
      raise "Schedule must be a hash." if !schedule.is_a? Hash
#            if !data.is_a?(Array)
#                data = [data]
#            end
      hash_to_send               = {}
      hash_to_send["payload"]    = data
      hash_to_send["class_name"] = class_name
      hash_to_send["schedule"]   = schedule
      add_sw_params(hash_to_send)
#            puts ' about to send ' + hash_to_send.inspect
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
      ret  = get("task/log", data, {:parse=>false})
#            puts ' ret=' + ret.inspect
#            ret["log"] = Base64.decode64(ret["log"])
      ret
    end


  end

end