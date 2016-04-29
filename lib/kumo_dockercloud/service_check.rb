module KumoDockerCloud
  class ServiceCheck
    attr_reader :checks, :timeout

    def initialize(checks = [], timeout = 300)
      @checks = checks
      @timeout = timeout
    end
  end
end