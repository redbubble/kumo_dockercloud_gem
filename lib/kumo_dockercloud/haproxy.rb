require 'csv'
require 'json'

module KumoDockerCloud
  class Haproxy
    def initialize(container_id, dc_user, dc_key)
      @container_id = container_id
      @client = DockerCloud::Client.new(dc_user, dc_key)
      @acc_data = ''
    end

    def stats
      cmd = 'sh -c "echo enable server default_service/REDBUBBLE_A_1 | nc -U /var/run/haproxy.stats"'
      @api = DockerCloud::ContainerStreamAPI.new(@container_id, cmd, @client.headers, @client)

      @api.on(:message) do |event|
        data = JSON.parse(event.data)['output']
        @acc_data << data
      end

      @api.on(:open) { |_| puts "Socket Opened" }
      @api.on(:error) { |event|
        raise HaproxySocketError.new(event.message)
      }
      @api.on(:close) do |_|
        puts 'Socket Closed'
        @api = nil
        return parse_stats(@acc_data)
      end

      @api.run!
    end

    def disable_server(server_name)
      cmd = %(sh -c "echo disable server default_service/#{server_name} | nc -U /var/run/haproxy.stats")
      @api = DockerCloud::ContainerStreamAPI.new(@container_id, cmd, @client.headers, @client)

      @api.on(:message) do |event|
        data = JSON.parse(event.data)['output']
        @acc_data << data
      end

      @api.on(:open) { |_| puts "Socket Opened" }
      @api.on(:error) { |event| raise HaproxySocketError.new(event.message) }
      @api.on(:close) do |_|
        puts 'Socket Closed'
        @api = nil
        return true
      end

      @api.run!
    end

    def enable_server(server_name)
      cmd = %(sh -c "echo enable server default_service/#{server_name} | nc -U /var/run/haproxy.stats")
      @api = DockerCloud::ContainerStreamAPI.new(@container_id, cmd, @client.headers, @client)

      @api.on(:message) do |event|
        data = JSON.parse(event.data)['output']
        @acc_data << data
      end

      @api.on(:open) { |_| puts "Socket Opened" }
      @api.on(:error) { |event| raise HaproxySocketError.new(event.message) }
      @api.on(:close) do |_|
        puts 'Socket Closed'
        @api = nil
        return true
      end

      @api.run!
    end

    private

    def parse_stats(stats)
      CSV.parse(stats, headers: true)
    end
  end
end
