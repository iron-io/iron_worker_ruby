require_relative 'test_base'
require_relative 'one_line_worker'

class QuickRun < TestBase

  def test_worker

    scheds = IronWorker.service.schedules(:project_id=>"4e71843298ea9b6b9f000004")
    puts scheds.inspect

    jobs = IronWorker.service.jobs(:project_id=>"4e71843298ea9b6b9f000004")
    puts jobs.inspect

    workers = IronWorker.service.code(:project_id=>"4e71843298ea9b6b9f000004")
    puts workers.inspect

    worker = OneLineWorker.new
    res = worker.queue(:project_id=>"4e71843298ea9b6b9f000004")
    puts "worker.queue returns:  " +  res.inspect
    job_id = res["task_id"]

    sleep 10

    log = worker.get_log(:project_id=>"4e71843298ea9b6b9f000004")
    puts log.inspect
  end

end

