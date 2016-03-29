module KumoDockerCloud
  class Stack
    attr_reader :stack_name, :app_name, :options

    def initialize(app_name, env_name, options = { contactable: true })
      @app_name = app_name
      @stack_name = "#{app_name}-#{env_name}"
      @options = options
    end

    def deploy(version)
      update_image(version)
      redeploy
      validate_deployment(version)
    end

    private

    def update_image(version)
      docker_cloud_api.services.update(service_uuid, image: "redbubble/#{app_name}:#{version}")
    end

    def redeploy
      docker_cloud_api.services.redeploy(service_uuid)
    end

    def validate_deployment(version)
      deployment = Deployment.new(stack_name, version)
      deployment.app_name = app_name
      deployment.contactable = options[:contactable]
      deployment.validate
    end

    def service_uuid
      @service_uuid ||= begin
        services = docker_cloud_api.services_by_stack_name(stack_name)
        services.first["uuid"]
      end
    end

    def docker_cloud_api
      @docker_cloud_api ||= KumoDockerCloud::DockerCloudApi.new
    end

  end
end
