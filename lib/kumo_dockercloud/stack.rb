require 'timeout'

module KumoDockerCloud
  class Stack
    attr_reader :stack_name, :app_name, :options

    def initialize(app_name, env_name, options = {})
      @app_name = app_name
      @stack_name = "#{app_name}-#{env_name}"
      @options = options
    end

    def deploy(service_name, version, checker = ServiceChecker.new)
      validate_params(service_name, 'Service name')
      validate_params(version, 'Version')

      service = Service.new(stack_name, service_name, docker_cloud_api)
      service.deploy(version)
      checker.verify(service)
    end

    def deploy_blue_green(service_names, version, checker = ServiceChecker.new)
      haproxy_service = HaproxyService.new(@stack_name, docker_cloud_api)

      services = service_names.map { |name| Service.new(stack_name, name, docker_cloud_api) }
      ordered_deployment(services).each do |service|
        begin
          ConsoleJockey.write_line("Attempting to put #{service.name} into maintenance mode in HAProxy")
          haproxy_service.disable_service(service) unless service.state == "Stopped"
          ConsoleJockey.write_line("Deploying version #{version} to #{service.name}")
          service.deploy(version)
          ConsoleJockey.write_line("Verifying that #{service.name} was successfully deployed")
          checker.verify(service)
          ConsoleJockey.write_line("Attempting to reenable #{service.name} in HAProxy")
          haproxy_service.enable_service(service)
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

    def kms
      @kms ||= KumoKi::KMS.new
    end

    def docker_cloud_api
      dockercloud_api_options = {}
      if @options[:encrypted_dockercloud_user] && @options[:encrypted_dockercloud_apikey]
        dockercloud_api_options.merge! KumoDockerCloud::CredentialsDecrypter.new.decrypt(@options)
      end

      @docker_cloud_api ||= DockerCloudApi.new(dockercloud_api_options)
    end
  end
end
