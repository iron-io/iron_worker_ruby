module IronWorker


  # Config is used to setup the IronWorker client.
  # You must set the access_key and secret_key.
  #
  # config.global_attributes allows you to specify attributes that will automatically be set on every worker,
  #    this is good for database connection information or things that will be used across the board.
  #
  # config.database configures a database connection. If specified like ActiveRecord, IronWorker will automatically establish a connection
  # for you before running your worker.
  class Config
    attr_accessor :token,
                  :project_id,
                  :scheme,
                  :host,
                  :port,
                  :global_attributes,
                  :models,
                  :mailers,
                  #:gems, # todo: move anything that uses this to merged_gems
                  :database,
                  :mailer,
                  :extra_requires,
                  #:auto_merge,
                  :server_gems,
                  :merged,
                  :unmerged,
                  :merged_gems,
                  :unmerged_gems,
                  :force_upload,
                  :beta


    def initialize
      @global_attributes = {}
      @extra_requires = []
      @merged = {}
      @unmerged = {}
      @merged_gems = {}
      @unmerged_gems = {}
      @mailers = {}

    end

    def access_key=(x)
      raise "IronWorker Config Error: access_key and secret_key are no longer used. The new IronWorker gem requires a couple of small configuration changes, please see: http://docs.IronWorker.com/ruby/new-gem-v2-update-guide for information."
    end
    def secret_key=(x)
      raise "IronWorker Config Error: access_key and secret_key are no longer used. The new IronWorker gem requires a couple of small configuration changes, please see: http://docs.IronWorker.com/ruby/new-gem-v2-update-guide for information."
    end

    @gems_to_skip = ['actionmailer', 'actionpack', 'activemodel', 'activeresource', 'activesupport',
                     'bundler',
                     'mail',
                     'mysql2',
                     'rails',
                     'tzinfo' # HUGE!
    ]

    def self.gems_to_skip
      @gems_to_skip
    end

    def bundle=(activate)
     if activate
       IronWorker.logger.info "Initializing IronWorker for Bundler..."
       IronWorker.configure do |c2|
         c2.merged_gems.merge!(get_required_gems)
         IronWorker.logger.debug "List of gems from bundler:#{c2.merged_gems.inspect}"
       end
     end
    end

    def auto_merge=(b)
      if b
        IronWorker.logger.info "Initializing IronWorker for Rails 3..."
        start_time = Time.now
        IronWorker.configure do |c2|
          models_path = File.join(Rails.root, 'app/models/*.rb')
          models = Dir.glob(models_path)
          c2.models = models
          models.each { |model| c2.merge(model) }
          mailers_path = File.join(Rails.root, 'app/mailers/*.rb')
          Dir.glob(mailers_path).collect { |m| c2.mailers[File.basename(m)] = {:filename=>m, :name => File.basename(m), :path_to_templates=>File.join(Rails.root, "app/views/#{File.basename(m, File.extname(m))}")} }
          c2.extra_requires += ['active_support/core_ext', 'action_mailer']
          #puts 'DB FILE=' + File.join(Rails.root, 'config', 'database.yml').to_s
          if defined?(ActiveRecord) && File.exist?(File.join(Rails.root, 'config', 'database.yml'))
            c2.extra_requires += ['active_record']
            c2.database = Rails.configuration.database_configuration[Rails.env]
          else
            #puts 'NOT DOING ACTIVERECORD'
          end

          if defined?(ActionMailer) && ActionMailer::Base.smtp_settings
            c2.mailer = ActionMailer::Base.smtp_settings
          end
          c2.merged_gems.merge!(get_required_gems)
          IronWorker.logger.debug "MODELS " + c2.models.inspect
          IronWorker.logger.debug "MAILERS " + c2.mailers.inspect
          IronWorker.logger.debug "DATABASE " + c2.database.inspect
          #IronWorker.logger.debug "GEMS " + c2.gems.inspect
        end
        end_time = Time.now
        IronWorker.logger.info "IronWorker initialized. Duration: #{((end_time.to_f-start_time.to_f) * 1000.0).to_i} ms"
      end
    end


    def get_required_gems
      #skipping if bundler not defined or not initialized
      return {} unless defined?(Bundler) && Bundler.instance_variables.include?(:@setup)
      gems_in_gemfile = Bundler.environment.dependencies.select { |d| d.groups.include?(:default) }
      IronWorker.logger.debug 'gems in gemfile=' + gems_in_gemfile.inspect
      gems = {}
      specs = Bundler.load.specs
      IronWorker.logger.debug 'Bundler specs=' + specs.inspect
      IronWorker.logger.debug "gems_to_skip=" + self.class.gems_to_skip.inspect
      specs.each do |spec|
        IronWorker.logger.debug 'spec.name=' + spec.name.inspect
        IronWorker.logger.debug 'spec=' + spec.inspect
        if self.class.gems_to_skip.include?(spec.name)
          IronWorker.logger.debug "Skipping #{spec.name}"
          next
        end
#        next if dep.name=='rails' #monkey patch
        gem_info = {:name=>spec.name, :version=>spec.version}
        gem_info[:auto_merged] = true
        gem_info[:merge] = spec.extensions.length == 0 #merging only non binary gems
        gem_info[:bypass_require] = true #don't require gem'
# Now find dependency in gemfile in case user set the require
        dep = gems_in_gemfile.find { |g| g.name == gem_info[:name] }
        if dep
          IronWorker.logger.debug 'dep found in gemfile: ' + dep.inspect
          IronWorker.logger.debug 'autorequire=' + dep.autorequire.inspect
          gem_info[:require] = dep.autorequire if dep.autorequire
#        spec = specs.find { |g| g.name==gem_info[:name] }
        end
        gem_info[:version] = spec.version.to_s
        gems[gem_info[:name]] = gem_info
        gemspec,path = IronWorker::Service.get_gem_path(gem_info)
        if path
          gem_info[:gemspec] = gemspec
          gem_info[:path] = path
          if gem_info[:require].nil? && dep
            # see if we should try to require this in our worker
            require_path = gem_info[:path] + "/lib/#{gem_info[:name]}.rb"
            IronWorker.logger.debug "require_path=" + require_path
            if File.exists?(require_path)
              IronWorker.logger.debug "File exists for require"
              gem_info[:require] = gem_info[:name]
            else
              IronWorker.logger.debug "no require"
#              gem_info[:no_require] = true
            end
          end
        else
          IronWorker.logger.warn "Could not find '#{gem_info[:name]}' specified in Bundler, continuing anyways."
        end
#        else
#          IronWorker.logger.warn "Could not find gem spec for #{gem_info[:name]}"
#          raise "Could not find gem spec for #{gem_info[:name]}"
#        end
      end
      gems
    end

    def get_server_gems
      return []
      # skipping this now, don't want any server dependencies if possible
      self.server_gems = IronWorker.service.get_server_gems unless self.server_gems
      self.server_gems
    end

    def get_atts_to_send
      config_data = {}
      config_data['token'] = token
      config_data['project_id'] = project_id
      config_data['database'] = self.database if self.database
      config_data['mailer'] = self.mailer if self.mailer
      config_data['global_attributes'] = self.global_attributes if self.global_attributes
      config_data['scheme'] = self.scheme if self.scheme
      config_data['host'] = self.host if self.host
      config_data['port'] = self.port if self.port
      config_data
    end

    def merge(file)
      f2 = IronWorker::MergeHelper.check_for_file(file, caller[2])
      fbase = f2[:basename]
      ret = f2
      @merged[fbase] = ret
      ret
    end

    def unmerge(file)
      f2 = IronWorker::MergeHelper.check_for_file(file, caller[2])
      fbase = f2[:basename]
      @unmerged[fbase] =f2
      @merged.delete(fbase)
    end

    # Merge a gem globally here
    def merge_gem(gem_name, options={})
      merged_gems[gem_name.to_s] = IronWorker::MergeHelper.create_gem_info(gem_name, options)
    end

    # Unmerge a global gem
    def unmerge_gem(gem_name)
      gs = gem_name.to_s
      gem_info = {:name=>gs}
      unmerged_gems[gs] = gem_info
      merged_gems.delete(gs)
    end

  end


  class MergeHelper

    # callerr is original file that is calling the merge function, ie: your worker.
    # See Base for examples.
    def self.check_for_file(f, callerr)
      IronWorker.logger.debug 'Checking for ' + f.to_s
      f = f.to_str
      f_ext = File.extname(f)
      if f_ext.empty?
        f_ext = ".rb"
        f << f_ext
      end
      exists = false
      if File.exist? f
        exists = true
      else
        # try relative
        #          p caller
        f2 = File.join(File.dirname(callerr), f)
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
      require f if f_ext == '.rb'
      ret = {}
      ret[:path] = f
      ret[:extname] = f_ext
      ret[:basename] = File.basename(f)
      ret[:name] = ret[:basename]
      ret
    end

    def self.create_gem_info(gem_name, options={})
      gem_info = {:name=>gem_name, :merge=>true}
      if options.is_a?(Hash)
        gem_info.merge!(options)
        if options[:include_dirs]
          gem_info[:include_dirs] = options[:include_dirs].is_a?(Array) ? options[:include_dirs] : [options[:include_dirs]]
        end
      else
        gem_info[:version] = options
      end

      gemspec, path = IronWorker::Service.get_gem_path(gem_info)
      IronWorker.logger.debug "Gem path=#{path}"
      if !path
        raise "Gem '#{gem_name}' not found."
      end
      gem_info[:gemspec] = gemspec
      gem_info[:path] = path
      gem_info[:require] ||= gem_name
      gem_info
    end
  end

end

