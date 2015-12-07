require 'tutum'

module KumoTutum

  def self.uuid_from_uri(uri)
    uri.split('/')[-1]
  end

  class TutumApi < ::Tutum
    # Note: Tutum handles the options in a "very" different way.
    def initialize(options = {})
      if options[:tutum_auth].nil?
        options[:username] ||= ENV['TUTUM_USER'] || read_user_id
        options[:api_key]  ||= ENV['TUTUM_APIKEY'] || read_api_key
      end

      super options
    end

    def stack_by_name(name)
      stacks.list['objects'].select { |s| s['name'].eql? name }.first
    end

    def services_by_stack_name(stack_name)
      stack = stack_by_name(stack_name)
      return [] unless stack
      stack['services'].collect do |uri|
        services.get(KumoTutum.uuid_from_uri(uri))
      end
    end

    def containers_by_stack_name(stack_name)
      services_by_stack_name(stack_name).collect do |data|
        data['containers'].collect do |uri|
          containers.get(KumoTutum.uuid_from_uri(uri))
        end
      end.flatten
    end

    def nodes_by_stack_name(stack_name)
      containers_by_stack_name(stack_name).collect do |data|
        nodes.get(KumoTutum.uuid_from_uri(data['node']))
      end
    end

    private

    def read_user_id
      tutum_config['user']
    end

    def read_api_key
      tutum_config['apikey']
    end

    def tutum_config_file
      File.open(File.expand_path('~/.tutum'))
    end

    def tutum_config
      if @config_data.nil?
        @config_data = {}

        handle = tutum_config_file
        handle.each_line do |line|
          parts = line.split('=', 2)
          if parts.length == 2 # ignore ini headers
            @config_data[parts[0].strip] = parts[1].strip
          end
        end

        handle.close
      end

      return @config_data
    end

  end
end