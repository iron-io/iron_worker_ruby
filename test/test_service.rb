require_relative 'test_base'

class ServiceTests < TestBase

  def test_codes
    resp = IronWorker.service.codes
    p resp
    assert resp["codes"]
    assert resp["codes"].is_a?(Array)
  end

  def test_tasks
    resp = IronWorker.service.tasks
    p resp


  end

end

