# KumoDockerCloud [![Build status](https://badge.buildkite.com/e9ebd06f4732bbb2a914228ac8816a2bbbeaf8bf0444ea00b4.svg)](https://buildkite.com/redbubble/kumo-docker-cloud)

This is the Redbubble wrapper around creating environments in docker cloud.  It is built into our rbdevltools container and can then be used during `apply-env` and `deploy` tasks. 

## Installation

This is installed into the rbdevtools container.

## Usage

Apply env example
```ruby
  KumoDockerCloud::Environment.new(
    name: environment_name,
    env_vars: env_vars,
    app_name: 'your-app-here',
    config_path: File.join('/app', 'config'),
    stack_template_path: File.join('/app', 'docker-cloud, 'stack.yml.erb')
  ).apply
```

Deploy example
```ruby
begin
  KumoDockerCloud::Stack.new(app_name, env_name).deploy(version)
rescue KumoDockerCloud::Deployment::DeploymentError, TimeoutError
  exit 1
end
```

## Testing changes

Changes to the gem can be manually tested end to end in a project that uses the gem (i.e. http-wala).

- First start the dev-tools container: `baxter kumo tools debug non-production`
- Re-install the gem: `gem specific_install https://github.com/redbubble/kumo_dockercloud_gem.git -b <your_branch>`
- Fire up a console: `irb`
- Require the gem: `require "kumo_dockercloud"`
- Interact with the gem's classes. `KumoDockerCloud::Stack.new('http-wala', 'test').deploy('1518')`


## Contributing

1. Fork it ( https://github.com/[my-github-username]/kumo_dockercloud_gem/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
