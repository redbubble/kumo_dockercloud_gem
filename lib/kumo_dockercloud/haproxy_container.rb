require 'csv'

module KumoDockerCloud
  class HaproxyContainer
    def initialize(container_id, client)
      @container_id = container_id
      @client = client
    end

    def stats
      CSV.parse(HaproxyCommand.new(@container_id, @client).execute('show stat'), headers: true)
    end

    def disable_server(server_name)
      current_stats = stats
      haproxy_server_record = current_stats.find { |stat| prefix_match? stat, server_name }

      raise HAProxyStateError.new("Unable to map #{server_name} to a HAProxy backend, I saw #{ get_server_names(current_stats) }") unless haproxy_server_record

      haproxy_server_name = haproxy_server_record['svname']

      HaproxyCommand.new(@container_id, @client).execute("disable server #{haproxy_server_name}")
    end

    def enable_server(server_name)
      HaproxyCommand.new(@container_id, @client).execute("enable server #{server_name}")
    end

    private

    def prefix_match?(stat_record, server_name)
      stat_record["svname"].downcase.start_with? server_name.downcase
    end

    def get_server_names(stats_object)
      stats_object.select { |record| record['# pxname'] == 'default_service' }.map { |record| record['svname']}.join(', ')
    end
  end
end
