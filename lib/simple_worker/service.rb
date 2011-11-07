require 'base64'
require 'logger'
require 'zip'
require 'rest_client'
require 'json'

require_relative 'api'

module SimpleWorker

  class Service < SimpleWorker::Api::Client

    attr_accessor :config

    def initialize(token, options={})
      if options[:config]
        self.config = options[:config]
      else
        c = SimpleWorker::Config.new unless self.config
        c.token = token
        self.config = c
      end
      options[:version] = SimpleWorker.api_version
      options[:logger] = SimpleWorker.logger
      super("worker-aws-us-east-1.iron.io", token, options)
      self.host = self.config.host if self.config && self.config.host
      # automerge simple worker gem and dependenices
      self.config.merge_gem('rest-client')
      self.config.merge_gem('simple_worker')
      SimpleWorker.logger.info 'SimpleWorker initialized.'
      SimpleWorker.logger.debug ' host = ' + self.host.inspect
    end

    # Options:
    #    - :callback_url
    #    - :merge => array of files to merge in with this file
    def upload(filename, class_name, options={})
      name = options[:name] || class_name
      project_id = get_project_id(options)
      tmp = Dir.tmpdir()
      md5file = "simple_worker_#{class_name.gsub("::", ".")}_#{token[0, 8]}.md5"
      existing_md5 = nil
      md5_f = File.join(tmp, md5file)
      if File.exists?(md5_f)
        existing_md5 = IO.read(md5_f)
      end
      # Check for code changes.
      md5 = Digest::MD5.hexdigest(File.read(filename))
      new_code = false
      if self.config.force_upload || md5 != existing_md5
        SimpleWorker.logger.info "Uploading #{class_name}, code modified."
        File.open(md5_f, 'w') { |f| f.write(md5) }
        new_code = true
        # todo: delete md5 file if error occurs during upload process
      else
#        puts "#{class_name}: same code, not uploading"
        return
      end

      begin

        zip_filename = build_merged_file(filename, options[:merge], options[:unmerge], options[:merged_gems], options[:merged_mailers], options[:merged_folders])

        if new_code
          upload_code(name, zip_filename, 'runner.rb', :runtime=>'ruby')
        end

      rescue Exception => ex
        # if it errors, let's delete md5 since it wouldn't have uploaded.
        File.delete(md5_f)
        raise ex
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
      gems = Gem::GemPathSearcher.new.init_gemspecs.select { |gem| gem.name==gem_name } if !gems || gems.empty?
      SimpleWorker.logger.debug 'gems found=' + gems.inspect
      gems = gems.select { |g| g.version.version==gem_info[:version] } if gem_info[:version]
      if !gems.empty?
        gem = gems.last
        gem.full_gem_path
      else
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
      SimpleWorker.logger.debug 'merged=' + merged.inspect

      merged_gems = merged_gems.merge(SimpleWorker.config.merged_gems)
      SimpleWorker.logger.debug 'merged_gems=' + merged_gems.inspect
      SimpleWorker.config.unmerged_gems.each_pair do |k, v|
        SimpleWorker.logger.debug 'unmerging gem=' + k.inspect
        merged_gems.delete(k)
      end
      SimpleWorker.logger.debug 'merged_gems_after=' + merged_gems.inspect

      merged_mailers ||= {}
      merged_mailers = merged_mailers.merge(SimpleWorker.config.mailers) if SimpleWorker.config.mailers

      #tmp_file = File.join(Dir.tmpdir(), File.basename(filename))
      tmp_file = File.join(Dir.tmpdir(), 'runner.rb')
      File.open(tmp_file, "w") do |f|

        f.write("
# Find environment (-e)
dirname = ''
i = 0
task_data_file = nil
task_id = nil
#puts \"args for single file=\" + ARGV.inspect
ARGV.each do |arg|
  if arg == \"-d\"
    # the user's writable directory
    dirname = ARGV[i+1]
  end
  if arg == \"-id\"
    # task_id
    task_id = ARGV[i+1]
  end
  if arg == \"-payload\"
    # path to job data
    task_data_file = ARGV[i+1]
  end
  i+=1
end
require 'json'
")
                           # require merged gems
        merged_gems.each_pair do |k, gem|
          SimpleWorker.logger.debug "Bundling gem #{gem[:name]}..."
          f.write "$LOAD_PATH << File.join(File.dirname(__FILE__), '/gems/#{gem[:name]}/lib')\n"
          SimpleWorker.logger.debug 'writing requires: ' + gem[:require].inspect
          if gem[:require].nil?
            gem[:require] = []
          elsif gem[:require].is_a?(String)
            gem[:require] = [gem[:require]]
          end
          SimpleWorker.logger.debug "gem[:require]: " + gem[:require].inspect
          gem[:require].each do |r|
            SimpleWorker.logger.debug 'adding require to file ' + r.to_s
            f.write "require '#{r}'\n"
          end
        end

            File.open(File.join(File.dirname(__FILE__), 'server', 'overrides.rb'), 'r') do |fr|
          while line = fr.gets
            f.write line
          end
        end

        # Now we must disable queuing while loading up classes. This is from the overrides.rb file
f.write("
SimpleWorker.disable_queueing()
")


        File.open(File.join(File.dirname(__FILE__), "server", 'runner.rb'), 'r') do |fr|
          while line = fr.gets
            f.write line
          end
        end

        # load job data
        f.write("
# Change to user directory
#puts 'dirname=' + dirname.inspect
Dir.chdir(dirname)
# Load in job data
job_data = JSON.load(File.open(task_data_file))
puts 'job_data=' + job_data.inspect
sw_config = job_data['sw_config']
")


        # add some rails stuff if using Rails
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

        if SimpleWorker.config.extra_requires
          SimpleWorker.config.extra_requires.each do |r|
            f.write "require '#{r}'\n"
          end
        end
        if merged_mailers && !merged_mailers.empty?
          # todo: isn't 'action_mailer already required in railtie?
          f.write "require 'action_mailer'\n"
          f.write "init_mailer(sw_config)\n"
          f.write "ActionMailer::Base.prepend_view_path('templates')\n"
        end
        f.write "init_database_connection(sw_config)\n"

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
        f.write("require_relative '#{File.basename(filename)}'\n")

        f.write("
  runner_class = get_class_to_run(job_data['class_name'])
  SimpleWorker.running_class = runner_class
  runner = init_runner(runner_class, job_data, dirname, task_id)
  init_worker_service_for_runner(job_data)

  # Now reenable after loading
  SimpleWorker.enable_queueing()

# Let's run it!
  runner_return_data = runner.run
")

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
            path = gem[:path]
            if path
              SimpleWorker.logger.debug "Collecting gem #{path}"
              paths_to_use = ["#{path}/*", "#{path}/lib/**/**"]
              if gem[:include_dirs]
                SimpleWorker.logger.debug "including extra dirs: " + gem[:include_dirs].inspect
                gem[:include_dirs].each do |dir|
                  paths_to_use << "#{path}/#{dir}/**/**"
                end
              end
              SimpleWorker.logger.debug 'paths_to_use: ' + paths_to_use.inspect
              Dir.glob(paths_to_use).each do |file|
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
                raise "Gem #{gem[:name]} #{gem[:version]} was not found. This will occour when gem_name.gemspec is not the same as the gems primary require."
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

        SimpleWorker.logger.debug "merge=" + merge.inspect
        merge.each_pair do |k, v|
          SimpleWorker.logger.debug "merging k=#{k.inspect} v=#{v.inspect} into #{filename}"
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

    # This will package up files into a zip file ready for uploading.
    def package_code(files)
      fname2 = "package.zip"
      File.delete(fname2) if File.exist?(fname2)
      Zip::ZipFile.open(fname2, 'w') do |f|
        files.each do |file|
          f.add(file, file)
        end
      end
      fname2
    end

    # options:
    #   :runtime => 'ruby', 'python', 'node', 'java', 'go'
    def upload_code(name, package_file, exec_file, options={})
      SimpleWorker.logger.info 'file size to upload: ' + File.size(package_file).to_s
      options = {
          "name"=>name,
          "standalone"=>true,
          "runtime"=>options[:runtime] || "ruby",
          "file_name"=> exec_file # File.basename(filename)
      }
      #puts 'options for upload=' + options.inspect
      SimpleWorker.logger.info "Uploading now..."
      ret = post_file("#{project_url_prefix(get_project_id(options))}codes", File.new(package_file), options)
      SimpleWorker.logger.info "Done uploading."
      return ret
    end

    def project_url_prefix(project_id = 0)
      # SimpleWorker.logger.info "project_url_prefix, project_id = " + project_id.inspect
      if project_id == 0
        return false
        project_id = config.project_id
      end
      "projects/#{project_id}/"
    end

    def wait_until_complete(task_id, options={})
      tries = 0
      status = nil
      sleep 1
      while tries < 100
        status = status(task_id)
        puts "Waiting... status=" + status["status"]
        if status["status"] != "queued" && status["status"] != "running"
          break
        end
        sleep 2
      end
      status
    end

    def add_sw_params(hash_to_send)
      # todo: remove secret key??  Can use worker service from within a worker without it now
      hash_to_send["oauth"] = self.token
      hash_to_send["api_version"] = SimpleWorker.api_version
    end

    def check_config
      if self.config.nil? || self.config.token.nil? || self.config.project_id.nil?
        raise "Invalid SimpleWorker configuration, token and project_id required."
      end
    end

    def enqueue(name, data={}, options={})
      queue(name, data, options)
    end

    # name: The name of previously upload worker code, eg: MySuperWorker
    # data: Arbitrary hash of your own data that your task will need to run.
    def queue(name, data={}, options={})
      puts "Queuing #{name}..."
      check_config
      if !data.is_a?(Array)
        data = [data]
      end
      # Now we need to add class_name to the payload
      tasks = []
      data.each do |d|
        d['class_name'] = name unless d['class_name']
        task = {}
        task["payload"] = d.to_json
        task["code_name"] = name
        task["priority"] = options[:priority] if options[:priority]
        task["timeout"] = options[:timeout] if options[:timeout]
        tasks << task
      end
      name = options[:name] || name
      hash_to_send = {}
      hash_to_send["options"] = options
      hash_to_send["tasks"] = tasks
      add_sw_params(hash_to_send)
      if defined?(RAILS_ENV)
        # todo: REMOVE THIS
        hash_to_send["rails_env"] = RAILS_ENV
      end
      return queue_raw(name, hash_to_send, options)
    end

    def queue_raw(name, data={}, options={})
      params = nil
      hash_to_send = data
      #hash_to_send["class_name"] = name unless hash_to_send["class_name"]
      hash_to_send["name"] = name unless hash_to_send["name"]
      uri = project_url_prefix(get_project_id(options)) + "tasks"
      SimpleWorker.logger.debug 'queue_raw , uri = ' + uri
      ret = post(uri, hash_to_send)
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
    def schedule(name, data, schedule)
      puts "Scheduling #{name}..."
      raise "Schedule must be a hash." if !schedule.is_a? Hash
      hash_to_send = {}
      schedules = []
      schedule["payload"] = data.to_json
      schedule["name"] = name unless schedule["name"]
      schedule["code_name"] = name unless schedule["code_name"]
      schedules << schedule
      hash_to_send["schedules"] = schedules
      add_sw_params(hash_to_send)
#            puts ' about to send ' + hash_to_send.inspect
      uri = project_url_prefix(get_project_id(data)) + "schedules"
      ret = post(uri, hash_to_send)
      ret
    end

    def cancel_schedule(scheduled_task_id, options={})
      raise "Must include a schedule id." if scheduled_task_id.blank?
      hash_to_send = {}
      hash_to_send["schedule_id"] = scheduled_task_id
      uri = "#{project_url_prefix(get_project_id(options))}schedules/#{scheduled_task_id}"
      delete(uri, hash_to_send)
    end

    def get_projects()
      hash_to_send = {}
      ret = get("projects", hash_to_send)
      ret
    end

    def get_project_id(options={})
      options[:project_id] || config.project_id
    end

    def get_project(options={})
      hash_to_send = {}

      ret = get("projects/"+ get_project_id(options) +"/", hash_to_send)
      #uri = project_url_prefix(id)
      #puts "get_project, uri = " + uri
      #ret = get(uri, hash_to_send)
      ret
    end

    def get_codes(options={})
      hash_to_send = {}
      uri = "projects/" + get_project_id(options) + "/codes/"
      ret = get(uri, hash_to_send)
      ret
    end

    def get_schedules(options={})
      hash_to_send = {}
      uri = "projects/" + get_project_id(options) + "/schedules/"
      ret = get(uri, hash_to_send)
      ret
    end

    def get_jobs(options={})
      hash_to_send = {}
      uri = "projects/" + get_project_id(options) + "/tasks/"
      ret = get(uri, hash_to_send)
      ret
    end

    def get_log(job_id, options={})
      log(job_id, options)
    end

    def log(task_id, options={})
      data = {}
      ret = get("#{project_url_prefix(get_project_id(options))}tasks/#{task_id}/log", data, :parse=>false)
      ret
    end


    def status(task_id, options={})
      data = {"task_id"=>task_id}
      ret = get("#{project_url_prefix(get_project_id(options))}tasks/#{task_id}", data)
      ret
    end

    def schedule_status(schedule_id, options={})
      data = {"schedule_id"=>schedule_id}
      ret = get("#{project_url_prefix(get_project_id(options))}schedules/#{schedule_id}", data)
      ret
    end

    # data is a hash, should include 'percent' and 'msg'
    def set_progress(task_id, options={})
      #data={"data"=>data, "task_id"=>task_id}
      post("#{project_url_prefix(get_project_id(options))}tasks/#{task_id}/progress", options)
    end


  end

end
