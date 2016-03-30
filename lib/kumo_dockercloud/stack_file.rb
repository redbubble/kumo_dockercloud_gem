require 'yaml'

module KumoDockerCloud
  module StackFile
    def self.create_from_template(stack_template, config, env_vars)
      parsed = YAML.load(ERB.new(stack_template).result(config.get_binding))

      parsed[config.app_name]['environment'] ||= {}
      parsed[config.app_name]['environment'].merge!(config.plain_text_secrets)
      parsed[config.app_name]['environment'].merge!(env_vars.fetch(config.app_name))

      converted_env_vars = make_all_root_level_keys_strings(env_vars)

      env_vars.each do |key, _|
        key_string = key.to_s
        parsed[key_string]['environment'].merge!(converted_env_vars.fetch(key_string))
      end

      parsed
    end

    def self.make_all_root_level_keys_strings(env_vars)
      env_vars.keys.reduce({}) { |acc, key| acc[key.to_s] = env_vars[key]; acc }
    end

    private_class_method :make_all_root_level_keys_strings
  end
end
