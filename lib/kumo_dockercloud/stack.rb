require 'timeout'

module KumoDockerCloud
  class Stack
    attr_reader :stack_name, :app_name, :options

    #TODO delete options
    def initialize(app_name, env_name, options = { contactable: true })
      @app_name = app_name
      @stack_name = "#{app_name}-#{env_name}"
      @options = options
    end

    def deploy(service_name, version, checker = ServiceChecker.new)
      validate_params(service_name, 'Service name')
      validate_params(version, 'Version')

      service = Service.new(stack_name, service_name)
      service.deploy(version)
      checker.verify(service)
    end

    def services
      services = docker_cloud_api.services_by_stack_name(stack_name)
      services.map { |service| Service.new(stack_name, service.name) }
    end

    def deploy_blue_green(service_names, version, checker = ServiceChecker.new)
      validate_params(version, "Version")
      validate_params(service_names, "Service names")

      puts "Service looks like: #{services.first.methods - methods}"

      all_services = services
      all_services.each do |service|
        puts "#{service.name} is currently #{service.state}"
      end
      active_service = all_services.select { |s| service_names.include?(s.name) && s.state == 'Running' }.first
      puts "Active server is: #{active_service.name}"

      haproxy_service = all_services.find { |s| s.name == 'haproxy' }

      inactive_service_name = service_names.find { |name| name != active_service.name }
      inactive_service = Service.new(stack_name, inactive_service_name)

      puts "Inactive server is: #{inactive_service.name}"

      # inactive_service.deploy(version)
      # checker.verify(inactive_service)

      haproxy = Haproxy.new(haproxy_service.uuid)
      puts "#{haproxy.stats}"

      # loop until haproxy indicates that our inactive service is up
      continue = false
      Timeout::timeout(30) {
        until(continue) do
          stats = haproxy.stats
          record = stats.find { | rec | rec['# pxrec'].downcase.start_with? inactive_service.downcase }
          continue = record['status'] == 'up'
          sleep 1
        end
      }



      # TODO: trigger haproxy connection draining on active service
      # TODO: wait for last connection to active service is > 3.0 seconds (or something)

      active_service.stop
    end

    private

    def validate_params(param_value, param_name)
      raise KumoDockerCloud::Error.new("#{param_name} cannot be nil") unless param_value
      raise KumoDockerCloud::Error.new("#{param_name} cannot be empty") if param_value.empty?
    end

    def docker_cloud_api
      @docker_cloud_api ||= DockerCloudApi.new
    end
  end
end
