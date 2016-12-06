module SimpleFeed
  module Fixtures

    def self.sample_feed
      # noinspection RubyResolve
      @sample_feed ||= Hashie::Mash.new(YAML.load(::File.read('spec/fixtures/sample_feed.yml')))
    end

    def self.mock_provider_props
      @mock_provider_props ||= ::SimpleFeed.symbolize!(self.sample_feed[:feeds].first.provider.to_hash)
    end

    def self.follow_feed
      @follow_feed ||= define_feed(:follow_feed)
    end

    def self.define_feed(feed_name)
      SimpleFeed.define(feed_name, **(::SimpleFeed.symbolize!(self.sample_feed[:feeds].first.to_hash)))
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
      define_method(m) do |user_ids:, **opts, &block|
        with_response_batched(user_ids) do |key, response|
          response.for(key.user_id) { opts[:result] || 0 }
        end
      end
    end

    NAME = 'I am a mock provider and I laugh at you'.freeze

    def name
      NAME
    end

    def method_call(m, **opts)
      puts "#{self.inspect}##{m}(#{opts.inspect})"
    end
  end
end

