module KumoDockerCloud
  class StackChecker
    def initialize(specific_checks = {}, common_check = nil, timeout = 300)
      @checks = specific_checks
      @default_check = common_check
      @docker_cloud_api = DockerCloudApi.new
      @timeout = timeout
    end

    # TODO: push stack access to the KumoDockerCloud::Stack object
    def verify(stack)
      service_check_threads = []
      services = @docker_cloud_api.services_by_stack_name(stack.name)

      default_checks = services.reduce({}) { |result, service| result.merge(service.name => default_check) }
      service_checks = default_checks.merge(@checks)
      begin
        services.each do |service|
          service_check_threads << Thread.new { ServiceChecker.new(service_checks[service.name], @timeout).verify(service) }
        end
        service_check_threads.each(&:join)
        true
      rescue ServiceDeployError
        raise StackCheckError.new("The stack is not in the expected state.")
      end
    end

    private

    def default_check
      @default_check ||= [lambda { |container| container.state == 'Running' }]
    end
  end
end
