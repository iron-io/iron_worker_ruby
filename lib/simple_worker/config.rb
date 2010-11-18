module SimpleWorker


    # Config is used to setup the SimpleWorker client.
    # You must set the access_key and secret_key.
    #
    # config.global_attributes allows you to specify attributes that will automatically be set on every worker,
    #    this is good for database connection information or things that will be used across the board.
    class Config
        attr_accessor :access_key,
                      :secret_key,
                      :host,
                      :global_attributes

        def initialize
            @global_attributes = {}
        end
    end

end

