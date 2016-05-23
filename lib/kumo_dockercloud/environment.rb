require 'yaml'
require 'erb'
require 'tempfile'
require 'forwardable'

require_relative 'console_jockey'
require_relative 'docker_cloud_api'
require_relative 'environment_config'
require_relative 'stack_file'
require_relative 'state_validator'
require_relative 'stack_checker'

module KumoDockerCloud
  class Environment
    extend ::Forwardable
    def_delegators :@config, :stack_name, :env_name

    def initialize(params = {})
      @env_name = params.fetch(:name)
      @env_vars = params.fetch(:env_vars, {})
      @stack_template_path = params.fetch(:stack_template_path)
      @timeout = params.fetch(:timeout, 120)
      @confirmation_timeout = params.fetch(:confirmation_timeout, 30)

      app_name = params.fetch(:app_name)
      @config = EnvironmentConfig.new(app_name: app_name, env_name: @env_name, config_path: params.fetch(:config_path))
    end

    def apply(service_checks=nil)
      if @config.image_tag == 'latest'
        ConsoleJockey.write_line 'WARNING: Deploying latest. The deployed container version may arbitrarily change'
      end

      stack_file = write_stack_config_file(configure_stack(stack_template))
      run_command(stack_command(stack_file))
      stack_file.unlink

      run_command("docker-cloud stack redeploy #{stack_name}")

      wait_for_running(@timeout)

      docker_cloud_api = DockerCloudApi.new
      stack = docker_cloud_api.stack_by_name(stack_name)

      begin
        StackChecker.new(service_checks).verify(stack)
      rescue StackCheckError
        raise EnvironmentApplyError.new("The stack is not in the expected state.")
      end
    end

    def destroy
      ConsoleJockey.flash_message "Warning! You are about to delete the Docker Cloud Stack #{stack_name}, enter 'yes' to continue."
      return unless ConsoleJockey.get_confirmation(@confirmation_timeout)
      run_command("docker-cloud stack terminate --sync #{stack_name}")
    end

    private

    def configure_stack(stack_template)
      StackFile.create_from_template(stack_template, @config, @env_vars)
    end

    def wait_for_running(timeout)
      StateValidator.new(stack_state_provider).wait_for_state('Redeploying', timeout)
      StateValidator.new(stack_state_provider).wait_for_state(expected_state, timeout)
      StateValidator.new(service_state_provider).wait_for_state('Running', timeout)
    end

    def expected_state
      env_name == 'production' ? 'Partly running' : 'Running'
    end

    def stack_state_provider
      docker_cloud_api = DockerCloudApi.new
      lambda {
        stack = docker_cloud_api.stack_by_name(stack_name)
        { name: stack.name, state: stack.state }
      }
    end

    def service_state_provider
      docker_cloud_api = DockerCloudApi.new
      lambda {
        services = docker_cloud_api.services_by_stack_name(stack_name)
        services.select! { |service| service.name != 'geckoboardwidget' }
        { name: 'services', state: services.map { |s| s.state }.uniq.join }
      }
    end

    def run_command(cmd)
      puts "Executing -> #{cmd}"
      puts `#{cmd}`
    end

    def evaluate_command(cmd)
      `#{cmd}`
    end

    def stack_command(stack_file)
      if exists?
        "docker-cloud stack update -f #{stack_file.path} #{stack_name}"
      else
        "docker-cloud stack create -f #{stack_file.path} -n #{stack_name}"
      end
    end

    def exists?
      result = evaluate_command('docker-cloud stack ls')
      result.include?(stack_name)
    end

    def write_stack_config_file(stack_file_data)
      output_file = Tempfile.new('docker-cloud_stack_config')
      output_file.write(stack_file_data.to_yaml)
      output_file.close
      output_file
    end

    def stack_template
      File.read(@stack_template_path)
    end
  end
end
