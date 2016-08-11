require 'kumo_ki'
require 'logger'

module KumoDockerCloud
  class EnvironmentConfig
    LOGGER = Logger.new(STDOUT)

    attr_reader :env_name, :app_name

    def initialize(options, logger = LOGGER)
      @env_name    = options.fetch(:env_name)
      @config_path = options.fetch(:config_path)
      @log         = logger
      @app_name    = options.fetch(:app_name)
      @app_image = options.fetch(:app_image)
    end

    def get_binding
      binding
    end

    def stack_name
      "#{app_name}-#{env_name}"
    end

    def deploy_tag
      production? ? 'production' : 'non-production'
    end

    def production?
      env_name == 'production'
    end

    def development?
      !(%w(production staging).include?(env_name))
    end

    def ruby_env
      return 'development' if development?
      env_name
    end

    def image_name
      if existing_image_name?
        existing_image_name
      else
        @app_image
      end
    end

    def tagged_app_image(service_name)
      service = docker_cloud_api.service_by_stack_and_service_name(stack_name, service_name)
      service ? service.image_name : @app_image
    end

    def image_tag
      image_name.split(':').last
    end

    def rails_env(name)
      if %w(development test cucumber demo staging production).include?(name)
        name
      else
        'demo'
      end
    end

    def config
      return @config if @config

      file = File.read(config_file_path)
      erb_result = ERB.new(file).result(get_binding)
      @config = YAML.load(erb_result)
    end

    def plain_text_secrets
      @plain_text_secrets ||= Hash[
        encrypted_secrets.map do |name, cipher_text|
          @log.info "Decrypting '#{name}'"
          if cipher_text.start_with? '[ENC,'
            begin
              [name, "#{kms.decrypt cipher_text[5, cipher_text.size]}"]
            rescue
              @log.error "Error decrypting secret '#{name}' from '#{encrypted_secrets_filename}'"
              raise
            end
          else
            [name, cipher_text]
          end
        end
      ]
    end

    def tags
      [deploy_tag]
    end

    def error_queue_url
      @error_queue_url ||= AssetWala::SqsQueue.get_error_queue_url
    end

    private

    def existing_image_name?
      !!existing_image_name
    end

    def existing_image_name
      @service ||= docker_cloud_api.services_by_stack_name(stack_name).first
      @service ? @service.image_name : nil
    end

    def docker_cloud_api
      @docker_cloud_api ||= KumoDockerCloud::DockerCloudApi.new
    end

    def kms
      @kms ||= KumoKi::KMS.new
    end

    def config_file_path
      path = File.join(config_path, "#{env_name}.yml")
      path = File.join(config_path, "development.yml") unless File.exist?(path)
      path
    end

    def encrypted_secrets_path
      secrets_filepath = File.join(config_path, "#{env_name}_secrets.yml")
      secrets_filepath = File.join(config_path, 'development_secrets.yml') unless File.exist?(secrets_filepath)
      secrets_filepath
    end

    def config_path
      File.expand_path(File.join(@config_path), __FILE__)
    end

    def encrypted_secrets_filename
      File.basename encrypted_secrets_path
    end

    def encrypted_secrets
      file = File.read(encrypted_secrets_path)
      erb_result = ERB.new(file).result(get_binding)
      @encrypted_secrets ||= YAML.load(erb_result)
    end
  end
end
