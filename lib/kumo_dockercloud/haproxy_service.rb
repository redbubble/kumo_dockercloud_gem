module KumoDockerCloud
  class HaproxyService < Service
    def initialize(stack_name, docker_cloud_api = DockerCloudApi.new)
      super(stack_name, 'haproxy', docker_cloud_api)

      @client = docker_cloud_api.client
    end

    def disable_service(service)
      service_to_disable = service.name
      haproxy_containers = containers.map { |container| HaproxyContainer.new(container.uuid, @client) }

      raise KumoDockerCloud::HAProxyStateError.new('Could not get instances of the haproxy container for this environment') if haproxy_containers.empty?

      haproxy_containers.each do |haproxy_container|
        haproxy_container.disable_server(service_to_disable)
      end
    end

    def enable_service(service)
      service_to_enable = service.name
      haproxy_containers = containers.map { |container| HaproxyContainer.new(container.uuid, @client) }

      raise KumoDockerCloud::HAProxyStateError.new('Could not get instances of the haproxy container for this environment') if haproxy_containers.empty?

      haproxy_containers.each do |haproxy_container|
        haproxy_container.enable_server(service_to_enable)
      end
    end
  end
end
