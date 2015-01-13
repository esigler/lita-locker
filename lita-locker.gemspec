Gem::Specification.new do |spec|
  spec.name          = 'lita-locker'
  spec.version       = '0.7.0'
  spec.authors       = ['Eric Sigler']
  spec.email         = ['me@esigler.com']
  spec.description   = '"lock" and "unlock" arbitrary subjects'
  spec.summary       = '"lock" and "unlock" arbitrary subjects'
  spec.homepage      = 'https://github.com/esigler/lita-locker'
  spec.license       = 'MIT'
  spec.metadata      = { 'lita_plugin_type' => 'handler' }

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(/^bin\//) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(/^(test|spec|features)\//)
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'lita', '>= 4.0.1'
  spec.add_runtime_dependency 'redis-objects'
  spec.add_runtime_dependency 'actionview'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '>= 3.0.0'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'simplecov'
end
