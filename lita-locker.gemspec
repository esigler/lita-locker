Gem::Specification.new do |spec|
  spec.name          = 'lita-locker'
  spec.version       = '1.0.1'
  spec.authors       = ['Eric Sigler']
  spec.email         = ['me@esigler.com']
  spec.description   = '"lock" and "unlock" arbitrary subjects'
  spec.summary       = '"lock" and "unlock" arbitrary subjects'
  spec.homepage      = 'https://github.com/esigler/lita-locker'
  spec.license       = 'MIT'
  spec.metadata      = { 'lita_plugin_type' => 'handler' }

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'lita', '>= 4.2'
  spec.add_runtime_dependency 'redis-objects'
  spec.add_runtime_dependency 'time-lord'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '>= 3.0.0'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'simplecov'

  spec.post_install_message = 'After upgrading to lita-locker 1.x, you should read: ' \
                              'https://github.com/esigler/lita-locker/blob/master/UPGRADING.md'
end
