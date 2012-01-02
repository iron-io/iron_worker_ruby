## This is a test for running a simple ruby script, not using the Base class.
#require_relative 'test_base'
#
#class ScriptTest < TestBase
#
#  def test_script
#    IronWorker.service.upload "one_line_worker.rb", "OneLineWorker"
#    queue_result = IronWorker.service.queue "simple_script_name", 'x'=>"attribute x"
#    status = IronWorker.service.wait_until_complete(queue_result)
#    assert status["status"] = "complete"
#    # todo: assert log contains our x attribute value
#  end
#
#end