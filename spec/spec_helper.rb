require 'simplecov'
SimpleCov.start

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'simplefeed'
require 'yaml'
require 'hashie'

module SimpleFeed
  module Fixtures

    def self.sample_feed
      @sample_feed ||= Hashie::Mash.new(YAML.load(File.read('spec/fixtures/sample_feed.yml')))
    end

    def self.mock_provider_properties
      Hashie::Extensions::SymbolizeKeys.symbolize_keys(self.sample_feed.feeds.first.provider.to_hash)
    end
  end
end
