require 'docker_cloud'

module KumoDockerCloud
  def self.uuid_from_uri(uri)
    uri.split('/')[-1]
  end

  class DockerCloudApi < ::DockerCloud::Client
    # Note: DockerCloud handles the options in a "very" different way.
    def initialize(options = {})
      authorize(options)
      super options[:username], options[:api_key]
    end

    def stack_by_name(name)
      stacks.list['objects'].find { |s| s['name'].eql? name }
    end

    def services_by_stack_name(stack_name)
      stack = stack_by_name(stack_name)
      return [] unless stack
      stack['services'].collect do |uri|
        services.get(KumoDockerCloud.uuid_from_uri(uri))
      end
    end

    def containers_by_stack_name(stack_name)
      services_by_stack_name(stack_name).collect do |data|
        data['containers'].collect do |uri|
          containers.get(KumoDockerCloud.uuid_from_uri(uri))
        end
      end.flatten
    end

    def nodes_by_stack_name(stack_name)
      containers_by_stack_name(stack_name).collect do |data|
        nodes.get(KumoDockerCloud.uuid_from_uri(data['node']))
      end
    end

    private

    def authorize(options)
      if options[:auth_header].nil?
        if !ENV['DOCKERCLOUD_USER'].nil? && !ENV['DOCKERCLOUD_APIKEY'].nil?
          options[:username] ||= ENV['DOCKERCLOUD_USER']
          options[:api_key]  ||= ENV['DOCKERCLOUD_APIKEY']
        else
          if read_basic_auth != nil
            options[:auth_header] = "Basic #{read_basic_auth}"
          else
            options[:username] ||= read_user_id
            options[:api_key]  ||= read_api_key
          end
        end
      end
      options
    end

    def read_basic_auth
      return unless docker_cloud_config['basic_auth']
      docker_cloud_config['basic_auth'][/\"([^@]+)\"/, 1]
    end

    def read_user_id
      docker_cloud_config['user']
    end

    def read_api_key
      docker_cloud_config['apikey']
    end

    def docker_cloud_config_file
      File.open(File.expand_path('~/.docker-cloud'))
    end

    def docker_cloud_config
      if @config_data.nil?
        @config_data = {}

        handle = docker_cloud_config_file
        handle.each_line do |line|
          parts = line.split('=', 2)
          @config_data[parts[0].strip] = parts[1].strip if parts.length == 2 # ignore ini headers
        end

        handle.close
      end

      @config_data
    end
  end
end
