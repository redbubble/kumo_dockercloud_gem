require 'csv'

module KumoDockerCloud
  class HaproxyService < Service
    def initialize(stack_name)
      super(stack_name, 'haproxy')

      @client = docker_cloud_api.client
    end

    def disable_service(service)
      service_to_disable = service.name
      haproxy_containers = containers.map { |container| HaproxyContainer.new(container.uuid, @client) }
      haproxy_containers.each { |haproxy_container| haproxy_container.disable_server(service_to_disable) }
    end
  end
end
