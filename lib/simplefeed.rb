# frozen_string_literal: true

require 'hashie/extensions/symbolize_keys'
require 'simplefeed/version'
require 'hashie'

Hashie.logger = Logger.new(nil)

::Dir.glob(::File.expand_path('../simplefeed/*.rb', __FILE__)).each { |f| require_relative(f) }

require 'simplefeed/providers/redis'
require 'simplefeed/providers/hash'
require 'simplefeed/dsl'
require 'simplefeed/feed'

# Main namespace module for the SimpleFeed gem. It provides several shortcuts and entry
# points into the library, such as ability to define and fetch new feeds via +define+,
# and so on.
module SimpleFeed
  @registry = {}

  class << self
    # @return Hash<Symbol, Feed> the registry of the defined feeds
    attr_reader :registry

    # @param <Symbol> name of the feed
    # @param <Hash> options any key-value pairs to set on the feed
    #
    # @return [Feed]  the feed with the given name, and defined via options and a block
    def define(name, **options)
      name = name.to_sym unless name.is_a?(Symbol)

      registry[name] ||= Feed.new(name)
      registry[name].tap do |feed|
        feed.configure(options) do
          yield(feed) if block_given?
        end
      end
    end

    # @param [Symbol] name
    # @return <Feed> the pre-defined feed with the given name
    def get(name)
      registry[name.to_sym]
    end

    # A factory method that constructs an instance of a provider based on the provider name and arguments.
    #
    # @param <Symbol> provider_name short name of the provider, eg, :redis, :hash, etc.
    # @param <Array> args constructor array arguments of the provider
    # @param <Hash, NilClass> opts constructor hash arguments of the provider
    #
    # @return <Provider>
    def provider(provider_name, *args, **opts, &block)
      provider_class = SimpleFeed::Providers.registry[provider_name]
      raise ArgumentError, "No provider named #{provider_name} was found, #{SimpleFeed::Providers.registry.inspect}" unless provider_class

      provider_class.new(*args, **opts, &block)
    end

    # Forward all other method calls to the Provider
    def method_missing(name, *args, **opts, &block)
      registry[name] || super
    end
  end

  # Returns list of class attributes based on the setter methods.
  # Not fool-proof, but works in this context.
  def self.class_attributes(klass)
    klass.instance_methods.grep(/[^=!]=$/).map { |m| m.to_s.gsub(/=/, '').to_sym }
  end

  # Shortcut method to symbolize hash keys, using Hashie::Extensions
  def self.symbolize!(hash)
    Hashie::Extensions::SymbolizeKeys.symbolize_keys!(hash)
  end
end
