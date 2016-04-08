module KumoDockerCloud
  class Service
    attr_reader :name, :uuid, :image_name

    def initialize(name, uuid, image_name)
      @name = name
      @uuid = uuid
      @image_name = image_name
    end

    def update_image(version)
      docker_cloud_api.services.update(@uuid, image: "redbubble/#{image_name}:#{version}")
    end

    private
    def docker_cloud_api
      @docker_cloud_api ||= KumoDockerCloud::DockerCloudApi.new
    end

  end
end