require 'timeout'

module KumoDockerCloud
  class Service
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

        true
      end
    rescue
      raise KumoDockerCloud::ServiceDeployError.new("One or more checks failed to pass within the timeout")
    end

    private
    attr_reader :stack_name, :name

    def containers
      service_api.containers
    end

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

    def service_api
      docker_cloud_api.service_by_stack_and_service_name(stack_name, name)
    end

    def uuid
      service_api.uuid
    end

    def image_name
      service_api.image_name.split(':').first
    end
  end
end
