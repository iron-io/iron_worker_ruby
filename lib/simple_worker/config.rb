module SimpleWorker


  # Config is used to setup the SimpleWorker client.
  # You must set the access_key and secret_key.
  #
  # config.global_attributes allows you to specify attributes that will automatically be set on every worker,
  #    this is good for database connection information or things that will be used across the board.
  #
  # config.database configures a database connection. If specified like ActiveRecord, SimpleWorker will automatically establish a connection
  # for you before running your worker.
  class Config
    attr_accessor :access_key,
                  :secret_key,
                  :host,
                  :global_attributes,
                  :models,
                  :mailers,
                  :gems,
                  :database,
                  :extra_requires,
                  :auto_merge



    def initialize
      @global_attributes = {}
      @extra_requires    = []
    end

    def get_atts_to_send
      config_data = {}
      config_data['database'] = self.database if self.database
      config_data['global_attributes'] = self.global_attributes if self.global_attributes
      config_data['host'] = self.host if self.host
      config_data
    end

  end

end

