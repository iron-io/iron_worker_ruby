require_relative 'test_base'
require_relative 'workers/webhook_worker'


class TestWebhooks < TestBase

  def test_webhook
    worker = WebhookWorker.new
    worker.upload

    code_name = worker.class.name
    payload = "webhooked!"

    # Now we hit the webhook
    @uber_client = Rest::Client.new
    puts 'TOKEN??? WTF?? ' + @token.inspect
    url = "#{IronWorker.service.base_url}/projects/#{@project_id}/tasks/webhook?code_name=#{code_name}&oauth=#{@token}"
    p url
    resp = @uber_client.post(url, {:body => payload})
    p resp
    body = JSON.parse(resp.body)
    p body

    @task_id = body["id"]

    url = "#{IronWorker.service.base_url}/projects/#{@project_id}/tasks/#{@task_id}?oauth=#{@token}"
    p url
    resp = @uber_client.get(url)
    p resp

    status = IronWorker.service.wait_until_complete(@task_id)
    p status
    assert status["status"]
    puts status["msg"]

    puts "LOG:"
    log = IronWorker.service.get_log(@task_id)
    puts log
    assert log.include?(payload)

  end


end

