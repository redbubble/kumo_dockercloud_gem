module KumoDockerCloud
  class ServiceChecker
    attr_reader :checks, :timeout, :quiet_time

    def initialize(checks = [], timeout = 300, quiet_time = 5)
      @checks = checks
      @timeout = timeout
      @quiet_time = quiet_time
    end

    def verify(service)
      Timeout::timeout(timeout) do

        while any_check_failing?(service)
          print '.'
          sleep(quiet_time)
        end

      end
    rescue Timeout::Error
      raise KumoDockerCloud::ServiceDeployError.new("One or more checks failed to pass within the timeout")
    end

    private

    def any_check_failing?(service)
      checks.each do |check|
        service.containers.each do |container|
          return true unless check.call(container)
        end
      end
      false
    end
  end
end
