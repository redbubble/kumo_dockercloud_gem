require 'csv'

module KumoDockerCloud
  class HaproxyService < Service
    def initialize(stack_name)
      super(stack_name, 'haproxy')

      @client = docker_cloud_api.client
    end

    def disable_service(service)
    end

  end
end
