# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'orats/version'

Gem::Specification.new do |spec|
  spec.name          = 'orats'
  spec.version       = Orats::VERSION
  spec.authors       = ['Nick Janetakis']
  spec.email         = ['nick.janetakis@gmail.com']
  spec.summary       = %q{Opinionated rails application templates.}
  spec.description   = %q{A collection of rails application templates using modern versions of Ruby on Rails. Launch new applications and the infrastructure to run them in seconds.}
  spec.homepage      = 'https://github.com/nickjj/orats'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'thor', '~> 0'

  spec.add_development_dependency 'bundler', '~> 1.5'
  spec.add_development_dependency 'rake', '~> 0'
end