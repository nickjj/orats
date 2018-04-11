lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'orats/version'

Gem::Specification.new do |spec|
  spec.name        = 'orats'
  spec.version     = Orats::VERSION
  spec.authors     = ['Nick Janetakis']
  spec.email       = ['nick.janetakis@gmail.com']
  spec.summary     = 'Opinionated rails application templates.'
  spec.description = 'Generate Dockerized Ruby on Rails applications ' \
                     'using best practices.'

  spec.homepage    = 'https://github.com/nickjj/orats'
  spec.license     = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(/^bin/) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(/^(test|spec|features)/)
  spec.require_paths = ['lib']

  spec.add_dependency 'thor', '~> 0'

  spec.add_development_dependency 'bundler', '~> 1.5'
  spec.add_development_dependency 'minitest', '~> 5.3'
  spec.add_development_dependency 'rake', '~> 0'
  spec.add_development_dependency 'rubocop', '~> 0.54'
end
