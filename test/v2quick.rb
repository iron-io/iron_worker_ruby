require_relative 'test_base'
require_relative 'one_line_worker'

class QuickRun < TestBase

  def test_worker
    projects = SimpleWorker.service.get_projects
    puts projects.inspect

    project = SimpleWorker.service.get_project("4e71843298ea9b6b9f000004")
    puts project.inspect
    
    scheds = SimpleWorker.service.get_schedules("4e71843298ea9b6b9f000004")
    puts scheds.inspect

    jobs = SimpleWorker.service.get_jobs("4e71843298ea9b6b9f000004")
    puts jobs.inspect

    workers = SimpleWorker.service.get_workers("4e71843298ea9b6b9f000004")
    puts workers.inspect

    worker = OneLineWorker.new
    res = worker.queue("4e71843298ea9b6b9f000004")
    puts "worker.queue returns:  " +  res.inspect
    job_id = res["task_id"]

    sleep 10

    log = worker.get_log("4e71843298ea9b6b9f000004", job_id)
    puts log.inspect
  end

end

