module KumoDockerCloud
  class Stack
    attr_reader :stack_name, :app_name, :options

    def initialize(app_name, env_name, options = { contactable: true })
      @app_name = app_name
      @stack_name = "#{app_name}-#{env_name}"
      @options = options
    end

    def deploy(service_name, version)
      # @service_uuid = service_uuid(service_name)
      service = Service.new(stack_name, service_name)
      service.update_image(version)
      service.redeploy
      validate_deployment(version)
    end

    def deploy_wait_for_exit(service_name, version)
      @service_uuid = service_uuid(service_name)
      update_image(version)
      redeploy
      validate_exit(version)
    end

    private



    def validate_deployment(version)
      deployment = Deployment.new(stack_name, version)
      deployment.app_name = app_name
      deployment.contactable = options[:contactable]
      deployment.validate
    end

    def validate_exit(version)
      deployment = Deployment.new(stack_name, version)
      deployment.app_name = app_name
      deployment.contactable = options[:contactable]
      deployment.wait_for_exit_state
    end




  end
end
