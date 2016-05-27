require 'csv'

module KumoDockerCloud
  class HaproxyService < Service
    def initialize(stack_name)
      super(stack_name, 'haproxy')

      @client = docker_cloud_api.client
    end

    def disable_service(service)
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
