require_relative 'test_base'

class TestInheritance < TestBase

  def test_who_am_i

    worker = TestWorker2.new
    puts "1: " + worker.who_am_i?
    puts "2: " + worker.who_am_i2?


  end

  def test_multi_subs
    t3 = TestWorker3.new
    t3.queue
    t3.wait_until_complete
    puts "LOG:"
    puts t3.get_log

  end

end