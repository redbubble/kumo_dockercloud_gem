module KumoDockerCloud
  class Stack
    attr_reader :stack_name, :app_name, :options

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
      timeout = options[:timeout]
      switching_service_name = options[:switching_service_name]

      switching_service = Service.new(stack_name, switching_service_name)
      green_service_name = switching_service.links.find { |service| service_names.include?(service.name) }
      blue_service_name = service_names.reject { |service| service.name == green_service_name }

      Service.new(stack_name, blue_service_name).deploy(version, checks, timeout)
    end

    private

    def validate_params(param_value, param_name)
      raise KumoDockerCloud::Error.new("#{param_name} cannot be nil") unless param_value
      raise KumoDockerCloud::Error.new("#{param_name} cannot be empty") if param_value.empty?
    end
  end
end
