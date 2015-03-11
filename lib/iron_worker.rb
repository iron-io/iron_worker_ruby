require 'json'

if (not ''.respond_to?(:start_with?)) or (not ''.respond_to?(:end_with?))
  class ::String
    def start_with?(prefix)
      prefix = prefix.to_s
      self[0, prefix.length] == prefix
    end

    def end_with?(suffix)
      suffix = suffix.to_s
      self[-suffix.length, suffix.length] == suffix
    end
  end
end

require 'iron_worker/version'
require 'iron_worker/api_client'
require 'iron_worker/client'
require 'iron_worker/worker_helper'

