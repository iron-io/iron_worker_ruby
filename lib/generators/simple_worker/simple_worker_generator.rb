class SimpleWorkerGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("../templates", __FILE__)
 
  desc "Creates a new skeleton worker - NAME is camelized"
  def create_worker_file
    # file_name needs to be classified
    @camel = file_name.camelize
    if not File.directory? "#{Rails.root}/app/workers"
      Dir.mkdir "#{Rails.root}/app/workers"
    end
    template "template_worker.erb", "app/workers/#{file_name}.rb" 
  end
end
