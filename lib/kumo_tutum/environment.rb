require 'yaml'
require 'erb'
require 'tempfile'
require 'forwardable'

require_relative 'tutum_api'
require_relative 'state_validator'
require_relative 'environment_config'
require_relative 'stack_file'

module KumoTutum
  class Environment
    extend ::Forwardable
    def_delegators :@config, :stack_name, :env_name

    def initialize(params = {})
      @env_name = params.fetch(:name)
      @env_vars = params.fetch(:env_vars, {})
      @stack_template_path = params.fetch(:stack_template_path)
      @timeout = params.fetch(:timeout, 120)

      app_name = params.fetch(:app_name)
      @config = EnvironmentConfig.new(app_name: app_name, env_name: @env_name, config_path: params.fetch(:config_path))
    end

    def apply
      if @config.image_tag == 'latest'
        puts 'WARNING: Deploying latest. The deployed container version may arbitrarily change'
      end

      stack_file = write_stack_config_file(configure_stack(stack_template))
      run_command(stack_command(stack_file))
      stack_file.unlink

      run_command("tutum stack redeploy #{stack_name}")

      wait_for_running(@timeout)
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
      tutum_api = TutumApi.new
      lambda { tutum_api.stack_by_name(stack_name) }
    end

    def service_state_provider
      tutum_api = TutumApi.new
      lambda {
        services = tutum_api.services_by_stack_name(stack_name)
        services.select! { |service| service['name'] != 'geckoboardwidget' }
        {'name' => 'services', 'state' => services.map { |s| s['state'] }.uniq.join}
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
        "tutum stack update -f #{stack_file.path} #{stack_name}"
      else
        "tutum stack create -f #{stack_file.path} -n #{stack_name}"
      end
    end

    def exists?
      result = evaluate_command('tutum stack list')
      result.include?(stack_name)
    end

    def write_stack_config_file(stack_file_data)
      output_file = Tempfile.new('tutum_stack_config')
      output_file.write(stack_file_data.to_yaml)
      output_file.close
      output_file
    end

    def stack_template
      File.read(@stack_template_path)
    end
  end
end
