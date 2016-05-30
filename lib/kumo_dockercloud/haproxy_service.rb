module KumoDockerCloud
  class HaproxyService < Service
    def initialize(stack_name)
      super(stack_name, 'haproxy')

      @client = docker_cloud_api.client
    end

    def disable_service(service)
      service_to_disable = service.name
      haproxy_containers = containers.map { |container| HaproxyContainer.new(container.uuid, @client) }

      raise KumoDockerCloud::HAProxyStateError.new('Could not get instances of the haproxy container for this environment') if haproxy_containers.empty?

      haproxy_threads = haproxy_containers.map { |haproxy_container| Thread.new { haproxy_container.disable_server(service_to_disable) } }
      haproxy_threads.each(&:join)

    end
  end
end
