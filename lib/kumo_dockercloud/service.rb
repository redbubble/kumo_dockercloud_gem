require 'timeout'

module KumoDockerCloud
  class Service
    attr_reader :name

    def initialize(stack_name, service_name)
      @stack_name = stack_name
      @name = service_name
    end

    def deploy(version)
      update_image(version)
      redeploy
    end

    def check(checks, timeout)
      Timeout::timeout(timeout) do
        all_tests_passed = true
        containers.each do |container|
          checks.each do |check|
            unless check.call(container)
              all_tests_passed = false
            end
          end
        end

        unless all_tests_passed
          print '.'
          sleep(5)
          check(checks, timeout)
        end
      end
    rescue
      raise KumoDockerCloud::ServiceDeployError.new("One or more checks failed to pass within the timeout")
    end

    def links
      get_service.linked_to_service.map { |service| KumoDockerCloud::Service.new(stack_name, service[:name]) }
    end

    def set_link(service_to_link)
      linked_service = {
        to_service: service_to_link.resource_uri,
        name: service_to_link.name,
        from_service: resource_uri
      }

      docker_cloud_api.services.update(uuid, linked_to_service: [linked_service])
    end

    def stop
      docker_cloud_api.services.stop(uuid)
    end

    def resource_uri
      get_service.resource_uri
    end

    def containers
      get_service.containers
    end

    private
    attr_reader :stack_name

    def update_image(version)
      docker_cloud_api.services.update(uuid, image: "#{image_name}:#{version}")
    rescue RestClient::InternalServerError
      raise KumoDockerCloud::ServiceDeployError.new("Something went wrong during service update on Docker Cloud's end")
    end

    def redeploy
      docker_cloud_api.services.redeploy(uuid)
    rescue RestClient::InternalServerError
      raise KumoDockerCloud::ServiceDeployError.new("Something went wrong during service update on Docker Cloud's end")
    end

    def docker_cloud_api
      @docker_cloud_api ||= KumoDockerCloud::DockerCloudApi.new
    end

    def get_service
      docker_cloud_api.service_by_stack_and_service_name(stack_name, name)
    end

    def uuid
      get_service.uuid
    end

    def image_name
      get_service.image_name.split(':').first
    end
  end
end
