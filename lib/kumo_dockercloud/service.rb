module KumoDockerCloud
  class Service
    def initialize(stack_name, service_name)
      @stack_name = stack_name
      @name = service_name
    end

    def update_image(version)
      docker_cloud_api.services.update(uuid, image: "#{image_name}:#{version}")
    end

    def redeploy
      docker_cloud_api.services.redeploy(uuid)
    end

    private
    attr_reader :stack_name, :name

    def docker_cloud_api
      @docker_cloud_api ||= KumoDockerCloud::DockerCloudApi.new
    end

    def service_api
      @service_api ||= docker_cloud_api.service_by_stack_and_service_name(stack_name, name)
    end

    def uuid
      service_api.uuid
    end

    def image_name
      service_api.image_name.split(':').first
    end

  end
end