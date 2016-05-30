module KumoDockerCloud
  class ServiceCheck
    attr_reader :error_message

    def initialize(lambda, error_message)
      @error_message = error_message
      @lambda = lambda
    end

    def call(container)
      @lambda.call(container)
    end
  end
end
