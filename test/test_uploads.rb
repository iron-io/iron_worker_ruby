require_relative 'test_base'

class IronWorkerTests < TestBase

  def test_uploads
    IronWorker.config.force_upload = false
    IronWorker.config.no_upload = true

    gen_worker

    IronWorker.config.no_upload = nil
    IronWorker.config.force_upload = true

    gen_worker

  end

  def gen_worker
    # copy our simplest worker
    new_file = "one_line_worker_#{Random.rand(100)}.rb"
    FileUtils.cp('workers/one_line_worker.rb', new_file)
    load new_file

    w = OneLineWorker.new
    w.queue
  end



end
