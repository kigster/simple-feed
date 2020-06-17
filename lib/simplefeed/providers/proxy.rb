# frozen_string_literal: true

module SimpleFeed
  module Providers
    RUBY_MAJOR_VERSION = RUBY_VERSION.split('.')[0..1].join.to_i

    class Proxy
      attr_accessor :provider

      def self.from(definition)
        if definition.is_a?(::Hash)
          ::SimpleFeed.symbolize!(definition)
          new(definition[:klass], *definition[:args], **definition[:opts])
        else
          new(definition)
        end
      end

      def initialize(provider_or_klass, *args, **options)
        self.provider = if provider_or_klass.is_a?(::String) || provider_or_klass.is_a?(::Symbol)
                          ::Object.const_get(provider_or_klass).new(*args, **options)
                        else
                          provider_or_klass
                        end

        SimpleFeed::Providers::REQUIRED_METHODS.each do |m|
          raise ArgumentError, "Invalid provider #{provider.class}\nMethod '#{m}' is required." unless provider.respond_to?(m)
        end
      end

      if RUBY_MAJOR_VERSION >= 27
        # Forward all other method calls to Provider
        def method_missing(name, *args, **opts, &block)
          if provider&.respond_to?(name)
            provider.send(name, *args, **opts, &block)
          else
            super(name, *args, **opts, &block)
          end
        end
      else
        # Forward all other method calls to Provider
        def method_missing(name, *args, &block)
          if provider&.respond_to?(name)
            provider.send(name, *args, &block)
          else
            super(name, *args, &block)
          end
        end
      end
    end
  end
end
