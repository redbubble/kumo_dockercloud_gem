require 'csv'

module KumoDockerCloud
  class Haproxy
    def initialize(container_id, dc_user, dc_key)
      @container_id = container_id
      @client = DockerCloud::Client.new(dc_user, dc_key)
    end

    def stats
      CSV.parse(HaproxyCommand.new(@container_id, @client).execute('show stat'), headers: true)
    end

    def disable_server(server_name)
      HaproxyCommand.new(@container_id, @client).execute("disable server #{server_name}")
    end

    def enable_server(server_name)
      HaproxyCommand.new(@container_id, @client).execute("enable server #{server_name}")
    end
  end
end
