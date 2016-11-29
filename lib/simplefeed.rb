require 'hashie/extensions/symbolize_keys'
require 'simplefeed/version'

::Dir.glob(::File.expand_path('../simplefeed/*.rb', __FILE__)).each { |f| require_relative(f) }

require 'simplefeed/providers/redis'
require 'simplefeed/providers/hash'
require 'simplefeed/dsl'

Float.class_eval do
  def near_eql?(other)
    delta = 0.001
    n     = (other - self).abs
    delta >= n
  end
end

module SimpleFeed
  @registry = {}

  def self.registry
    @registry
  end

  def self.define(name, **options, &block)
    name = name.to_sym unless name.is_a?(Symbol)
    feed = registry[name] ? registry[name] : SimpleFeed::Feed.new(name)
    feed.configure(options) do
      block.call(feed) if block
    end
    registry[name] = feed
    feed
  end

  def self.get(name)
    registry[name.to_sym]
  end

  def self.dsl(object, **opts, &block)
    if object.kind_of?(SimpleFeed::Activity::Base)
      SimpleFeed::DSL.for_activity(object, **opts, &block)
    else
      raise TypeError, 'Only SimpleFeed::Activity classes are wrapped by the DSL...'
    end
  end

  def self.provider(provider_name, *args, **opts, &block)
    provider_class = SimpleFeed::Providers.registry[provider_name]
    raise ArgumentError, "No provider named #{provider_name} was found, #{SimpleFeed::Providers.registry.inspect}" unless provider_class
    provider_class.new(*args, **opts, &block)
  end

  class << self
    # Forward all other method calls to Provider
    def method_missing(name, *args, &block)
      registry[name] || super
    end
  end

  # Returns list of class attributes based on the setter methods.
  # Not fool-proof, but works in this context.
  def self.class_attributes(klass)
    klass.instance_methods.grep(%r{[^=!]=$}).map { |m| m.to_s.gsub(/=/, '').to_sym }
  end

  def self.symbolize!(hash)
    Hashie::Extensions::SymbolizeKeys.symbolize_keys!(hash)
  end
end
