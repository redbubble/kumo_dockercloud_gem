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

      handler = KumoDockerCloud::HaproxyEventHandler.new
      api.on(:open, &handler.on_open)
      api.on(:message, &handler.on_message)
      api.on(:error, &handler.on_error)
      api.on(:close, &handler.on_close)

      api.run!
      handler.data
    end
  end
end
