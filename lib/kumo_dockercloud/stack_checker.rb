module KumoDockerCloud
  class StackChecker
    def initialize(specific_checks = {}, common_check = nil, timeout = 300)
      @checks = specific_checks
      @default_check = common_check
      @timeout = timeout
    end

    def verify(stack)
      raise InvalidStackError.new("The stack being verified is not a valid KumoDockerCloud::Stack.") unless stack.instance_of? KumoDockerCloud::Stack

      services = stack.services

      default_checks = services.reduce({}) { |result, service| result.merge(service.name => default_check) }
      service_checks = default_checks.merge(@checks)

      begin
        service_checker_threads = services.map do |service|
          Thread.new { ServiceChecker.new(service_checks[service.name], @timeout).verify(service) }
        end
        service_checker_threads.each(&:join)
        true
      rescue ServiceDeployError
        raise StackCheckError.new("The stack is not in the expected state.")
      end
    end

    private

    def default_check
      @default_check ||= [ServiceCheck.new(lambda { |container| container.state == 'Running' }, "Service is not running")]
    end
  end
end
