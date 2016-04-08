module KumoDockerCloud
  class Service
    attr_reader :stack_name, :service_name, :image_name

    def initialize(stack_name, service_name, image_name)
      @stack_name = stack_name
      @service_name = service_name
      @image_name = image_name
    end

    def update_image(version)
      docker_cloud_api.services.update(uuid, image: "#{image_name}:#{version}")
    end

    private
    def docker_cloud_api
      @docker_cloud_api ||= KumoDockerCloud::DockerCloudApi.new
    end

    def uuid
      docker_cloud_api.service_by_stack_and_service_name(stack_name, service_name).uuid
    end

  end
end