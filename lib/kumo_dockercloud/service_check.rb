module KumoDockerCloud
  class ServiceCheck
    attr_reader :checks, :timeout

    def initialize(checks = [], timeout = 300)
      @checks = checks
      @timeout = timeout
    end

    def verify(service)
      Timeout::timeout(timeout) do
        all_tests_passed = true
        checks.each do |check|
          service.containers.each do |container|
            unless check.call(container)
              all_tests_passed = false
            end
          end
        end

        unless all_tests_passed
          print '.'
          sleep(5)
          check(checks, timeout)
        end
      end
    rescue
      raise KumoDockerCloud::ServiceDeployError.new("One or more checks failed to pass within the timeout")
    end
  end
end