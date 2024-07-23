# frozen_string_literal: true

require 'simplecov'

if ENV['CODECOV_TOKEN']
  require 'codecov'
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end

SimpleCov.start do
  # e.g., usage of track files
  track_files "lib/**/*.rb"
end

require 'yaml'
require 'hashie'

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'simplefeed'
require 'simplefeed/version'
require 'simple-feed'
require 'simple_feed'
require 'rspec/its'

::Dir.glob(::File.expand_path('../support/*.rb', __FILE__)).sort.each do |f|
  require_relative(f)
end

SimpleFeed::DSL.debug = false
SimpleFeed::Providers::Redis.debug = false

RSpec.configure do |config|
  config.include(SimpleFeed::DSL)
end

USER_IDS_TO_TEST = [199_929_993_999, 12_289_734, 12, UUID.generate, 'R1.COMPOSITE.0X2F8F7D'].freeze
