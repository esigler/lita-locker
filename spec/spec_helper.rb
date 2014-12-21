require 'simplecov'
require 'coveralls'
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start { add_filter '/spec/' }

require 'lita-locker'
require 'lita/rspec'
Lita.version_3_compatibility_mode = false

RSpec.configure do |config|
  config.before do
    registry.register_handler(Lita::Handlers::LockerLabels)
    registry.register_handler(Lita::Handlers::LockerResources)
  end
end
