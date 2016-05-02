require 'docker_cloud'
require 'base64' # left out of DockerCloud gem

module KumoDockerCloud
  class DockerCloudApi
    extend Forwardable
    def_delegator :@client, :services

    def initialize(options = {})
      options[:username] ||= ENV['DOCKERCLOUD_USER']
      options[:api_key] ||= ENV['DOCKERCLOUD_APIKEY']

      @client = options[:client] || ::DockerCloud::Client.new(options.fetch(:username), options.fetch(:api_key))
    end

    def stack_by_name(name)
      @client.stacks.all.find { |s| s.name == name }
    end

    def services_by_stack_name(stack_name)
      stack = stack_by_name(stack_name)
      return [] unless stack
      stack.services
    end

    def service_by_stack_and_service_name(stack_name, service_name)
      services = services_by_stack_name(stack_name)
      services.find { |s| s.name == service_name }
    end

    def containers_by_stack_name(stack_name)
      services_by_stack_name(stack_name).collect do |service|
        service.containers
      end.flatten
    end

    def service_by_resource_uri(resource_uri)
      @client.services.get_from_uri(resource_uri)
    end
  end
end
