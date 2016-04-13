module IronWorker
  VERSION = "3.2.3"

  def self.version
    VERSION
  end

  def self.full_version
    'iron_worker_ruby_-' + IronWorker.version + ' (iron_core_ruby-' + IronCore.version + ')'
  end
end
