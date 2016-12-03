require 'simplecov'
SimpleCov.start

require 'yaml'
require 'hashie'

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'simplefeed'
require 'rspec/its'

::Dir.glob(::File.expand_path('../support/*.rb', __FILE__)).each { |f| require_relative(f) }

SimpleFeed::DSL.debug = false
SimpleFeed::Providers::Redis.debug = false

RSpec.configure do |config|
  config.include(SimpleFeed::DSL)
end
