require 'kumo_ki'
require 'logger'

module KumoTutum
  class EnvironmentConfig
    LOGGER = Logger.new(STDOUT)

    APP_NAME = 'asset-wala'

    attr_reader :env_name

    def initialize(options, logger = LOGGER)
      @env_name    = options.fetch(:env_name)
      @config_path = options.fetch(:config_path)
      @log         = logger

      # AssetWala::QueueName.env_name = @env_name
    end

    def get_binding
      binding
    end

    def stack_name
      "#{APP_NAME}-#{env_name}"
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
        "redbubble/#{APP_NAME}:latest"
      end
    end

    def image_tag
      image_name.split(':').last
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
      @service_data ||= tutum_api.services_by_stack_name(stack_name).first
      @service_data ? @service_data['image_name'] : nil
    end

    def tutum_api
      @tutum_api ||= KumoTutum::TutumApi.new
    end

    def kms
      @kms ||= KumoKi::KMS.new
    end

    def encrypted_secrets_path
      config_path      = File.expand_path(File.join(@config_path), __FILE__)
      secrets_filepath = File.join(config_path, "#{env_name}_secrets.yml")
      secrets_filepath = File.join(config_path, 'development_secrets.yml') unless File.exist?(secrets_filepath)
      secrets_filepath
    end

    def encrypted_secrets_filename
      File.basename encrypted_secrets_path
    end

    def encrypted_secrets
      puts encrypted_secrets_path
      file               = File.read(encrypted_secrets_path)
      erb_result = ERB.new(file).result(get_binding)
      @encrypted_secrets ||= YAML.load(erb_result)
    end

  end
end