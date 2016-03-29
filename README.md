# KumoTutum [![Build status](https://badge.buildkite.com/e9ebd06f4732bbb2a914228ac8816a2bbbeaf8bf0444ea00b4.svg)](https://buildkite.com/redbubble/kumo-tutum-gem)

This is the Redbubble wrapper around creating environments in tutum.  It is built into our rbdevltools container and can then be used during `apply-env` and `deploy` tasks. 

## Installation

This is installed into the rbdevtools container.

## Usage

Apply env example
```ruby
  KumoTutum::Environment.new(
    name: environment_name,
    env_vars: env_vars,
    app_name: 'your-app-here',
    config_path: File.join('/app', 'config'),
    stack_template_path: File.join('/app', 'tutum', 'stack.yml.erb')
  ).apply
```

Deploy example
```ruby
begin
  KumoTutum::Stack.new(app_name, env_name).deploy(version)
rescue KumoTutum::Deployment::DeploymentError, TimeoutError
  exit 1
end
```

## Testing changes

Changes to the gem can be manually tested end to end in a project that uses the gem (i.e. http-wala).

- First start the dev-tools container: `baxter kumo tools debug non-production`
- Re-install the gem: `gem specific_install https://github.com/redbubble/kumo_tutum_gem.git -b <your_branch>`
- Fire up a console: `irb`
- Require the gem: `require "kumo_tutum"`
- Interact with the gem's classes. `KumoTutum::Stack.new('http-wala', 'test').deploy('1518')`


## Contributing

1. Fork it ( https://github.com/[my-github-username]/kumo_tutum/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
