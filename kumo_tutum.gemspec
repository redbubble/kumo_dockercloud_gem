# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kumo_tutum/version'

Gem::Specification.new do |spec|
  spec.name          = 'kumo_tutum'
  spec.version       = KumoTutum::VERSION
  spec.authors       = %w(Redbubble)
  spec.email         = %w(developers@redbubble.com)
  spec.summary       = %q{Use to create Redbubble environments on the Tutum platform}
  spec.description   = %q{Use to create Redbubble environments on the Tutum platform}
  spec.homepage      = ''
  spec.license       = 'mit'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.4'
  spec.add_development_dependency 'webmock', '~> 1.22'
end
