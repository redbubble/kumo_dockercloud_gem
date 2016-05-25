require 'json'

module KumoDockerCloud
  class HaproxyCommand
    def initialize(container_id, dc_client)
      @container_id = container_id
      @dc_client = dc_client
    end

    def execute(command)
      cmd = %(sh -c "echo #{command} | nc -U /var/run/haproxy.stats")
      api = DockerCloud::ContainerStreamAPI.new(@container_id, cmd, @dc_client.headers, @dc_client)

      api.on(:open) { |event| on_open(event) }
      api.on(:message) { |event| on_message(event) }
      api.on(:error) { |event| on_error(event) }
      api.on(:close) { |event| on_close(event) }

      api.run!
      @acc_data
    end
  end

  private

  def on_open(_)
    @acc_data = ''
  end

  def on_message(event)
    data = JSON.parse(event.data)['output']
    @acc_data << data
  end

  def on_error(event)
    raise HaproxySocketError.new(event.message)
  end

  def on_close(event)
    EventMachine.stop
  end
end
