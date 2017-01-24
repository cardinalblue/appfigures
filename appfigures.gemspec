# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'appfigures/version'

Gem::Specification.new do |spec|
  spec.name          = 'appfigures'
  spec.version       = AppFigures::VERSION
  spec.authors       = ['JimYTC', 'Tiffany Chiang']
  spec.email         = ['solofat@gmail.com', 'tchiang@andrew.cmu.edu']

  spec.summary       = %q{Ruby client for access AppFigures API}
  spec.description   = %q{Wrap up AppFigures API calls to fasten access}
  spec.homepage      = 'https://github.com/cardinalblue/appfigures'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  else
    raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.14'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rspec', '~> 3.5'
  spec.add_development_dependency 'webmock', '~> 2.3'

  spec.add_runtime_dependency 'typhoeus', '~> 1.1'
end
