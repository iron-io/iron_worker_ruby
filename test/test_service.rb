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
    assert resp["tasks"]
    assert resp["tasks"].is_a?(Array)
  end

  def test_schedules
      resp = IronWorker.service.schedules
      p resp
      assert resp["schedules"]
      assert resp["schedules"].is_a?(Array)
  end


end

