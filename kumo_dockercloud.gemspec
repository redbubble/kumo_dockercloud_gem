# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kumo_dockercloud/version'

Gem::Specification.new do |spec|
  spec.name          = 'kumo_dockercloud'
  spec.version       = KumoDockerCloud::VERSION
  spec.authors       = %w(Redbubble Delivery Engineering)
  spec.email         = %w(delivery-engineering@redbubble.com)
  spec.summary       = %q{Use to create Redbubble environments on the DockerCloud platform}
  spec.description   = %q{Use to create Redbubble environments on the DockerCloud platform}
  spec.homepage      = ''
  spec.license       = 'mit'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'httpi', '~> 2.4'
  spec.add_runtime_dependency 'docker_cloud', '~> 0.1'
  spec.add_runtime_dependency 'kumo_ki', '~>1.0'

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.4'
  spec.add_development_dependency 'webmock', '~> 1.22'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rubocop', '~> 0.40'
end
