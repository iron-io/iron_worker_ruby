# encoding: UTF-8
# This could be a gem to help worker users with common functions like getting config and payload.
require 'json'

module IronWorker
  @@loaded = false
  @@args = {}
  @@payload = {}
  @@config = {}

  def self.loaded
    return @@loaded
  end

  def self.load
    return if @@loaded

    0.upto($*.length - 2) do |i|
      @@args[:root] = $*[i + 1] if $*[i] == '-d'
      @@args[:payload_file] = $*[i + 1] if $*[i] == '-payload'
      @@args[:config_file] = $*[i + 1] if $*[i] == '-config'
      @@args[:task_id] = $*[i + 1] if $*[i] == '-id'
    end

    # New way is ENV vars, so check those too
    # TASK_ID
    # PAYLOAD_FILE
    # TASK_DIR
    # CONFIG_FILE
    @@args[:task_id] = ENV['TASK_ID'] if ENV['TASK_ID']
    @@args[:payload_file] = ENV['PAYLOAD_FILE'] if ENV['PAYLOAD_FILE']
    @@args[:config_file] = ENV['CONFIG_FILE'] if ENV['CONFIG_FILE']
    @@args[:root] = ENV['TASK_DIR'] if ENV['TASK_DIR']

    # puts "args: #{@@args.inspect}"

    if args[:payload_file]
      @@payload = File.open(@@args[:payload_file], "r:UTF-8", &:read)
      begin
        @@payload = JSON.parse(@@payload)
      rescue => ex
        puts "Couldn't parse IronWorker payload into json, leaving as string. #{ex}"
      end
    end

    if args[:config_file]
      if args[:config_file]
        @@config = File.read(args[:config_file])
        begin
          @@config = JSON.parse(@@config)
        rescue
          # try yaml
          begin
            @@config = YAML.load(@@config)
          rescue => ex

          end
        end
      end
    end
    @@loaded = true
  end

  def self.payload
    load
    @@payload
  end

  def self.config
    load
    @@config
  end

  def self.task_id
    @@args[:task_id]
  end

  def self.args
    return @@args
  end

end
