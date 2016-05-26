require_relative 'console_jockey'

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
          ConsoleJockey.write_char '.'
          sleep(quiet_time)
        end

      end
    rescue Timeout::Error
      if @error_messages.length > 0
        raise KumoDockerCloud::ServiceDeployError.new("One or more checks failed to pass within the timeout. Message: #{@error_messages.first}")
      else
        raise KumoDockerCloud::ServiceDeployError.new("One or more checks failed to pass within the timeout. I'd show you what went wrong but the checks were lambdas so I can't. Maybe you should update your usage to the new ServiceCheck object instead of lambdas?")
      end
    end

    private

    def any_check_failing?(service)
      @error_messages = []
      checks.each do |check|
        service.containers.each do |container|
          unless check.call(container)
            if check.respond_to?(:error_message) 
              @error_messages << check.error_message
            end
            return true
          end
        end
      end
      false
    end
  end
end
