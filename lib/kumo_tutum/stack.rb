module KumoTutum
  class Stack
    attr_reader :stack_name, :app_name

    def initialize(app_name, env_name)
      @app_name = app_name
      @stack_name = "#{app_name}-#{env_name}"
    end

    def deploy(version)
      update_image(version)
      redeploy
      validate_deployment(version)
    end

    private

    def update_image(version)
      tutum_api.services.update(service_uuid, image: "redbubble/#{app_name}:#{version}")
    end

    def redeploy
      tutum_api.services.redeploy(service_uuid)
    end

    def validate_deployment(version)
      deployment = Deployment.new(stack_name, version)
      deployment.app_name = app_name
      deployment.validate
    end

    def service_uuid
      @service_uuid ||= begin
        services = tutum_api.services_by_stack_name(stack_name)
        services.first["uuid"]
      end
    end

    def tutum_api
      @tutum_api ||= KumoTutum::TutumApi.new
    end

  end
end