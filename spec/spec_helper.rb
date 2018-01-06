# frozen_string_literal: true

require 'simplecov'
require 'coveralls'
SimpleCov.formatters = [
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start { add_filter '/spec/' }

require 'lita-locker'
require 'lita/rspec'
Lita.version_3_compatibility_mode = false

RSpec.configure do |config|
  config.before do
    registry.register_hook(:trigger_route, Lita::Extensions::KeywordArguments)
    registry.register_handler(Lita::Handlers::Locker)
    registry.register_handler(Lita::Handlers::LockerEvents)
    registry.register_handler(Lita::Handlers::LockerHttp)
    registry.register_handler(Lita::Handlers::LockerLabels)
    registry.register_handler(Lita::Handlers::LockerMisc)
    registry.register_handler(Lita::Handlers::LockerResources)
  end
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.filter_run :focus
  config.run_all_when_everything_filtered = true
  config.default_formatter = 'doc' if config.files_to_run.one?
  config.order = :random

  Kernel.srand config.seed
end
