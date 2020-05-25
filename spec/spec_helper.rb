# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  # e.g., usage of track files
  track_files "lib/**/*.rb"
end

require 'codecov'
SimpleCov.formatter = SimpleCov::Formatter::Codecov

require 'yaml'
require 'hashie'

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'simplefeed'
require 'rspec/its'

::Dir.glob(::File.expand_path('../support/*.rb', __FILE__)).each { |f| require_relative(f) }

SimpleFeed::DSL.debug = false
SimpleFeed::Providers::Redis.debug = false

RSpec.configure do |config|
  config.include(SimpleFeed::DSL)
end

USER_IDS_TO_TEST = [199_929_993_999, 12_289_734, 12, UUID.generate, 'R1.COMPOSITE.0X2F8F7D'].freeze
