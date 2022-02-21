# frozen_string_literal: true

require 'yaml'
require 'simplefeed/providers/redis'
require 'simplefeed/providers/redis/provider'

FEED_FILE    = ::IO.read('spec/fixtures/sample_feed.yml').freeze
YAML_CLASSES = [::Integer, ::String, ::Symbol, ::Time, ::Hash, ::Float, ::SimpleFeed::Providers::Redis::Provider].freeze
FEED_SPEC    = ::YAML.safe_load(FEED_FILE, permitted_classes: YAML_CLASSES, symbolize_names: true)
#.each do |c|
#   add(c.delete(:name), c.delete(:value), c)
# end.freeze

module SimpleFeed
  module Fixtures
    def self.sample_feed
      # noinspection RubyResolve

      @sample_feed ||= Hashie::Mash.new(FEED_SPEC)
    end

    def self.mock_provider_props
      @mock_provider_props ||= ::SimpleFeed.symbolize!(sample_feed[:feeds].first.provider.to_hash)
    end

    def self.follow_feed
      @follow_feed ||= define_feed(:follow_feed)
    end

    def self.define_feed(feed_name)
      SimpleFeed.define(feed_name, **::SimpleFeed.symbolize!(sample_feed[:feeds].first.to_hash))
    end
  end

  class MockProvider < SimpleFeed::Providers::Base::Provider
    attr_accessor :host, :port, :db, :namespace

    def initialize(host, port, db:, namespace: nil)
      self.host      = host
      self.port      = port
      self.db        = db
      self.namespace = namespace
    end

    SimpleFeed::Providers::REQUIRED_METHODS.each do |m|
      define_method(m) do |user_ids:, **opts|
        with_response_batched(user_ids) do |key, response|
          response.for(key.consumer) { opts[:result] || 0 }
        end
      end
    end

    NAME = 'I am a mock provider and I laugh at you'

    def name
      NAME
    end

    def method_call(m, **opts)
      puts "#{inspect}##{m}(#{opts.inspect})"
    end
  end
end
