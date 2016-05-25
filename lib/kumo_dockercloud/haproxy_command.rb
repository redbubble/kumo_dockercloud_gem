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

      api.on(:open) { |_| @acc_data = '' }

      api.on(:message) do |event|
        data = JSON.parse(event.data)['output']
        @acc_data << data
      end

      api.on(:error) { |event|
        raise HaproxySocketError.new(event.message)
      }

      api.on(:close) do |_|
        puts 'Socket Closed'
        @api = nil
        EventMachine.stop
      end

      api.run!
      @acc_data
    end
  end
end
