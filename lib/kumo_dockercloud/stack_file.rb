require 'yaml'

module KumoDockerCloud
  module StackFile
    def self.create_from_template(stack_template, config, env_vars)
      parsed = YAML.load(ERB.new(stack_template).result(config.get_binding))

      converted_env_vars = make_all_root_level_keys_strings(env_vars)

      env_vars.each do |key, _|
        key_string = key.to_s
        parsed[key_string]['environment'] ||= {}
        parsed[key_string]['environment'].merge!(converted_env_vars.fetch(key_string))
        parsed[key_string]['environment'] = escape_characters_that_need_special_handling(parsed[key_string]['environment'])
      end

      parsed
    end

    def self.make_all_root_level_keys_strings(env_vars)
      env_vars.keys.reduce({}) { |acc, key| acc[key.to_s] = env_vars[key]; acc }
    end

    def self.escape_characters_that_need_special_handling(env_hash)
      env_hash.keys.reduce do |acc, key|
        if env_hash[key].is_a? String
          acc[key] = (env_hash[key].is_a? String) ? env_hash[key].gsub(/[$]{1}/, "$$")
        elsif env_hash[key].is_a? Numeric
          acc[key] = env_hash[key]
        else
          raise KumoDockerCloud::StackFileError("Unable to handle environment key #{key} with value #{env_hash[key]} of class #{env_hash[key].class} which does not inherit from Numeric or String")
        end
        acc
      end
    end

    private_class_method :make_all_root_level_keys_strings
  end
end
