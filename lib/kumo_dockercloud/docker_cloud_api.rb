require 'docker_cloud'
require 'base64' # left out of DockerCloud gem

module KumoDockerCloud
  class DockerCloudApi
    # Note: DockerCloud handles the options in a "very" different way.
    def initialize(options = {})
      @client = ::DockerCloud::Client.new(options[:username], options[:api_key])
    end

    def stack_by_name(name)
      @client.stacks.all.find { |s| s.name == name }
    end

    def services_by_stack_name(stack_name)
      stack = stack_by_name(stack_name)
      return [] unless stack
      stack.services
    end

    def containers_by_stack_name(stack_name)
      services_by_stack_name(stack_name).collect do |service|
        service.containers
      end.flatten
    end
  end
end
