# KumoDockerCloud 
[![Build status](https://badge.buildkite.com/d22efc59148d48d86ca78e6129340070d1a459031a019fff48.svg)](https://buildkite.com/redbubble/kumo-dockercloud-gem) [![Code Climate](https://codeclimate.com/github/redbubble/kumo_dockercloud_gem/badges/gpa.svg)](https://codeclimate.com/github/redbubble/kumo_dockercloud_gem)

This is the Redbubble wrapper around creating environments in docker cloud.  It is built into our rbdevltools container and can then be used during `apply-env` and `deploy` tasks.

## Installation

This is installed into the rbdevtools container.

## Usage

### Apply env example

By default apply-env will check that all services within the stack are running:

```ruby
  KumoDockerCloud::Environment.new(
    name: environment_name,
    env_vars: env_vars,
    app_name: 'your-app-here',
    config_path: File.join('/app', 'config'),
    stack_template_path: File.join('/app', 'docker-cloud', 'stack.yml.erb')
  ).apply()
```

This is not desirable for stacks with services that are not permanently running.

#### StackChecker

For these situations you can pass in a stack checker object which maps services to a custom set of checks as follows:

```ruby
  require 'kumo_dockercloud'

   custom_checks = {
    'transitory_service' => [
      lambda { |container| container.state == 'Stopped' },
      lambda { |container| container.exit_code == 0 }
    ]
  }

  stack_checker = KumoDockerCloud::StackChecker.new(custom_checks)

  KumoDockerCloud::Environment.new(
    name: environment_name,
    env_vars: env_vars,
    app_name: 'your-app-here',
    config_path: File.join('/app', 'env', 'config'),
    stack_template_path: File.join('/app', 'env', 'docker-cloud', 'stack.yml.erb'),
    timeout: 600
  ).apply(stack_checker)
```

The `StackChecker` will execute default checks for all services in your stack which are not listed
in the custom checks. The default check is that the service is running. You can override this by
passing in your own set of default checks as follows:

```ruby
  default_checks = [
    lambda { |container| container.state == 'Awesome' },
    lambda { |container| container.logs.contain? 'Ready' }
  ]

  stack_checker = KumoDockerCloud::StackChecker.new(custom_checks, default_checks, 120)
```

The third parameter in the line above is the timeout, by default is 300 seconds.

### Deploy example

The deploy method will deploy your docker image to a service within an existing stack
(i.e. you've created the `Environment` as above):

```ruby
begin
  KumoDockerCloud::Stack.new(app_name, env_name).deploy(service_name, version)
rescue KumoDockerCloud::Deployment::DeploymentError, TimeoutError
  exit 1
end
```

The `version` is your Docker Hub tag on an image name that matches what is in your
Docker Cloud stackfile.

#### ServiceChecker

By default deploy will not run any checks on the services that you deploy. You can override
this by passing in a service checker:

```ruby
  custom_service_checks = [
   lambda { |container| container.state == 'Stopped' },
   lambda { |container| container.exit_code == 0 }
 ]

  service_checker = KumoDockerCloud::ServiceChecker.new(custom_service_checks, 120)

  KumoDockerCloud::Stack.new(app_name, env_name).deploy(service_name, version, service_checker)

```
As for the `StackChecker`, the third parameter is a timeout which defaults to 300 seconds.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/kumo_dockercloud_gem/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Changelog

This section records potentially breaking changes to the API or User Experience.

### Version 3.0.0

Destroying a stack now requires user confirmation at the console before the action will be carried out.
