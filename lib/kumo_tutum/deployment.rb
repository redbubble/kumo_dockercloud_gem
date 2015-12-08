require 'time'
require 'httpi'

require_relative 'tutum_api'
require_relative 'state_validator'

module KumoTutum
  class Deployment

    class DeploymentError < StandardError; end

    attr_reader :service_uuid, :stack_name, :version, :health_check_path, :version_check_path

    def initialize(stack_name, version, service_uuid)
      @stack_name = stack_name
      @version = version
      @service_uuid = service_uuid

      @health_check_path = 'site_status'
      @version_check_path = "#{health_check_path}/version"
    end

    def validate
      wait_for_running_state
      validate_containers
    end

    def wait_for_running_state
      service_state_provider = lambda { tutum_api.services.get(service_uuid) }
      StateValidator.new(service_state_provider).wait_for_state('Running', 240)
    end

    private

    def tutum_api
      @tutum_api ||= KumoTutum::TutumApi.new
    end

    def current_state
      return 'an unknown state' if @parsed_service_info.nil?
      @parsed_service_info.fetch('state', 'an unknown state')
    end

    def validate_containers
      puts "Getting containers"

      containers = tutum_api.containers_by_stack_name(stack_name)

      HTTPI.log = false

      containers.each do |container|
        validate_container_data(container)
      end
    end

    def validate_container_data(container)
      unless container["name"].start_with?("asset-wala")
        puts "Skipping #{container["name"]}"
        return
      end
      print "Checking '#{container['name']}' (#{container['uuid']}): "

      raise "Unexpected number of open container ports" if container['container_ports'].size != 1
      endpoint_uri = container['container_ports'].first['endpoint_uri'].gsub(/^tcp:/, 'http:')

      validate_container_version(endpoint_uri)
      validate_container_health(endpoint_uri)
      print "\n"
    end

    def validate_container_version(endpoint_uri)
      version_check_uri = "#{endpoint_uri}#{version_check_path}"
      print "Version "
      response = safe_http_get(version_check_uri)
      actual_version = response.body.strip

      if actual_version == version
        print "OK, "
      else
        puts "Incorrect: Should be '#{version}'; reported '#{actual_version}'"
        raise DeploymentError.new
      end
    end

    def validate_container_health(endpoint_uri)
      health_check_uri = "#{endpoint_uri}#{health_check_path}"
      print "Health "
      response = safe_http_get(health_check_uri)
      if response.code == 200
        print "OK"
      else
        puts "Unhealthy (HTTP #{response.code}): #{response.body}"
        raise DeploymentError.new
      end
    end

    def safe_http_get(url)
      tries ||= 3
      HTTPI.get(url)
    rescue Timeout::Error, Errno::ECONNREFUSED, Errno::EINVAL, Errno::ECONNRESET, Errno::ETIMEDOUT, EOFError,
        Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
      sleep 5
      retry unless (tries -= 1).zero?
    end

  end
end
