module KumoDockerCloud
  class Stack
    attr_reader :stack_name, :app_name, :options

    #TODO delete options
    def initialize(app_name, env_name, options = { contactable: true })
      @app_name = app_name
      @stack_name = "#{app_name}-#{env_name}"
      @options = options
    end

    def deploy(service_name, version, checks = nil, check_timeout = 300)
      validate_params(service_name, 'Service name')
      validate_params(version, 'Version')

      service = Service.new(stack_name, service_name)
      service.deploy(version)
      service.check(checks, check_timeout) if checks
    end

    def deploy_blue_green(options)
      service_names = options[:service_names]
      version = options[:version]
      checks = options[:checks]
      check_timeout = options[:check_timeout]
      switching_service_name = options[:switching_service_name]

      validate_params(version, "Version")
      validate_params(service_names, "Service names")
      validate_params(switching_service_name, "Switching service name")

      services = service_names.map { |service_name| Service.new(stack_name, service_name) }

      switching_service = Service.new(stack_name, switching_service_name)
      green_service = switching_service.links.find { |linked_service| services.find { |service| service.name == linked_service.name } }
      blue_service = services.find { |service| service.name != green_service.name }

      blue_service.deploy(version)
      blue_service.check(checks, check_timeout) if checks

      switching_service.set_link(blue_service)
      green_service.stop
    end

    private

    def validate_params(param_value, param_name)
      raise KumoDockerCloud::Error.new("#{param_name} cannot be nil") unless param_value
      raise KumoDockerCloud::Error.new("#{param_name} cannot be empty") if param_value.empty?
    end
  end
end
