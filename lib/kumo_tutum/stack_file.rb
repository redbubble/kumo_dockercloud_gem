module KumoTutum
  module StackFile
    def self.create_from_template(stack_template, config, env_vars)
      parsed = YAML.load(ERB.new(stack_template).result(config.get_binding))

      parsed[config.app_name]['environment'] ||= {}
      parsed[config.app_name]['environment'].merge!(config.plain_text_secrets)
      parsed[config.app_name]['environment'].merge!(env_vars.fetch(config.app_name))

      parsed
    end
  end
end