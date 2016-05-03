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

      validate_params(version, "Version")
      validate_params(service_names, "Service names")
      validate_params(switching_service_name, "Switching service name")

      switching_service = Service.new(stack_name, switching_service_name)
      link = switching_service.links.find { |link| service_names.include?(Service.service_by_resource_uri(link[:to_service]).name) }
      active_service = Service.service_by_resource_uri(link[:to_service])

      inactive_service_name = service_names.find { |name| name != active_service.name }
      inactive_service = Service.new(stack_name, inactive_service_name)

      inactive_service.deploy(version)
      checker.verify(inactive_service)

      switching_service.set_link(inactive_service, link[:name])
      active_service.stop
    end

    private

    def validate_params(param_value, param_name)
      raise KumoDockerCloud::Error.new("#{param_name} cannot be nil") unless param_value
      raise KumoDockerCloud::Error.new("#{param_name} cannot be empty") if param_value.empty?
    end
  end
end
