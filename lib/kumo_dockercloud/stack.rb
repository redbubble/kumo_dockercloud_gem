module KumoDockerCloud
  class Stack
    attr_reader :stack_name, :app_name, :options

    #TODO delete options
    def initialize(app_name, env_name, options = { contactable: true })
      @app_name = app_name
      @stack_name = "#{app_name}-#{env_name}"
      @options = options
    end

    def deploy(service_name, version, checker = ServiceChecker.new)
      validate_params(service_name, 'Service name')
      validate_params(version, 'Version')

      service = Service.new(stack_name, service_name)
      service.deploy(version)
      checker.verify(service)
    end

    def deploy_blue_green(options)
      service_names = options[:service_names]
      version = options[:version]
      checker = options[:checker] || ServiceChecker.new
      switching_service_name = options[:switching_service_name]
      switching_service_internal_link_name = options[:switching_service_internal_link_name]

      validate_params(version, "Version")
      validate_params(service_names, "Service names")
      validate_params(switching_service_name, "Switching service name")
      validate_params(switching_service_internal_link_name, "Switching service internal link name")

      services = service_names.map { |service_name| Service.new(stack_name, service_name) }

      switching_service = Service.new(stack_name, switching_service_name)
      active_service = switching_service.links.find { |linked_service| service_names.include?(linked_service.name) }
      inactive_service = services.find { |service| service.name != active_service.name }

      inactive_service.deploy(version)
      checker.verify(inactive_service)

      switching_service.set_link(inactive_service, switching_service_internal_link_name)
      active_service.stop
    end

    private

    def validate_params(param_value, param_name)
      raise KumoDockerCloud::Error.new("#{param_name} cannot be nil") unless param_value
      raise KumoDockerCloud::Error.new("#{param_name} cannot be empty") if param_value.empty?
    end
  end
end
