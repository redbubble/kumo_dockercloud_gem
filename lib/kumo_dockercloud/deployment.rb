require 'time'
require 'httpi'

require_relative 'docker_cloud_api'
require_relative 'state_validator'

module KumoDockerCloud
  class Deployment

    class DeploymentError < StandardError; end

    attr_accessor :app_name, :contactable
    attr_reader :stack_name, :version, :health_check_path, :version_check_path

    def initialize(stack_name, version, _ = nil)
      @stack_name = stack_name
      @version = version
      @contactable = true

      @health_check_path = 'site_status'
      @version_check_path = "#{health_check_path}/version"
    end

    def validate
      wait_for_running_state
      validate_containers
    end

    def wait_for_running_state
      service_state_provider = lambda {
        service = docker_cloud_api.services.get(service_uuid)
        { name: service.name, state: service.state }
      }

      StateValidator.new(service_state_provider).wait_for_state('Running', 240)
    end

    def wait_for_exit_state
      exit_state_provider = lambda {
        service = docker_cloud_api.services.get(service_uuid)
        { name: service.name, exit_code: service.containers.first.exit_code }
      }

      StateValidator.new(exit_state_provider).wait_for_exit_state(240)
    end

    private

    def service_uuid(service_name)
      @service_uuid ||= begin
        services = docker_cloud_api.service_by_stack_and_service_name(stack_name, service_name)
        services.first.uuid
      end
    end

    def docker_cloud_api
      @docker_cloud_api ||= KumoDockerCloud::DockerCloudApi.new
    end

    def current_state
      return 'an unknown state' if @parsed_service_info.nil?
      @parsed_service_info.fetch('state', 'an unknown state')
    end

    def validate_containers
      puts "Getting containers"

      containers = docker_cloud_api.containers_by_stack_name(stack_name)

      HTTPI.log = false

      containers.each do |container|
        validate_container_data(container)
      end
    end

    def validate_container_data(container)
      unless container.name.start_with?(app_name)
        puts "Skipping #{container.name}"
        return
      end
      print "Checking '#{container.name}' (#{container.uuid}): "

      raise "Unexpected number of open container ports" if container.container_ports.size != 1

      if contactable
        endpoint_uri = container.container_ports.first.endpoint_uri.gsub(/^tcp:/, 'http:')
        validate_container_version(endpoint_uri)
        validate_container_health(endpoint_uri)
      end
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
      request = HTTPI::Request.new(url: url, open_timeout: 5, read_timeout: 5)
      HTTPI.get(request)
    rescue Timeout::Error, Errno::ECONNREFUSED, Errno::EINVAL, Errno::ECONNRESET, Errno::ETIMEDOUT, EOFError,
        Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
      sleep 5

      if (tries -= 1).zero?
        raise e
      else
        retry
      end
    end
  end
end
