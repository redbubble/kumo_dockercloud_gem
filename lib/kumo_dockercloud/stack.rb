require 'timeout'

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

    def deploy_blue_green(service_names, version, checker = ServiceChecker.new)
      haproxy_service = HaproxyService.new(@stack_name)

      services = service_names.map { |name| Service.new(stack_name, name) }
      ordered_deployment(services).each do |service|
        begin
          haproxy_service.disable_service(service) unless service.state == "Stopped"
          service.deploy(version)
          checker.verify(service)
        rescue HAProxyStateError => e
          raise ServiceDeployError.new("Unable to place service #{service.name} into maintainance mode on HAProxy with message: #{e.message}")
        rescue ServiceDeployError => e
          haproxy_service.disable_service(service)
          raise ServiceDeployError.new("Deployment or verification of service #{service.name} failed with message: #{e.message}")
        end
      end
    end

    def services
      services = docker_cloud_api.services_by_stack_name(stack_name)
      services.map { |service| Service.new(stack_name, service.name) }
    end

    private

    def ordered_deployment(services)
      services.sort { |service_a, service_b| service_b.state <=> service_a.state }
    end

    def validate_params(param_value, param_name)
      raise KumoDockerCloud::Error.new("#{param_name} cannot be nil") unless param_value
      raise KumoDockerCloud::Error.new("#{param_name} cannot be empty") if param_value.empty?
    end

    def docker_cloud_api
      @docker_cloud_api ||= DockerCloudApi.new
    end
  end
end
