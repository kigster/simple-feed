# frozen_string_literal: true

require_relative 'key'
require_relative 'providers/proxy'

module SimpleFeed
  module Providers
    @registry = {}

    class << self
      attr_reader :registry

      def register(provider_name, provider_class)
        registry[provider_name] = provider_class
      end
    end

    module PublisherMethods
      def self.included(base)
        ::SimpleFeed::Providers.define_proxy_methods_on(base, type: :publisher)
      end
    end

    module ConsumerMethods
      def self.included(base)
        ::SimpleFeed::Providers.define_proxy_methods_on(base, type: :consumer)
      end
    end

    # These methods must be implemented by each Provider, and operation on a given
    # set of users passed via the consumers: parameter.
    PROVIDER_METHODS = {
      publisher: %i[publish store],
      consumer:  %i[
        delete
        delete_if
        wipe
        reset_last_read
        last_read
        paginate
        fetch
        total_count
        unread_count
      ],
      utility:   %i[total_memory_bytes total_users]
    }.freeze

    # Methods required to be implemented by any provider
    REQUIRED_METHODS = PROVIDER_METHODS.values.flatten.freeze

    class << self
      def define_proxy_methods_on(base, type: nil)
        ::SimpleFeed::Providers.define_provider_methods(base, type) do |instance, method, *args, **opts, &block|
          opts.merge!(consumers: instance.consumers)
          if opts[:event]
            opts.merge!(data: opts[:event].data, at: opts[:event].at)
            opts.delete(:event)
          end
          instance.feed.send(method, *args, **opts, &block).tap do |response|
            raise StandardError, "Nil response from provider #{instance.feed.provider&.provider&.class}, method #{method}(#{opts})" unless response

            block&.call(response)
          end
        end
      end

      def define_provider_methods(klass, type = nil, &block)
        klass.instance_eval do
          ::SimpleFeed::Providers.method_list(type).each do |method_name|
            define_method(method_name) do |*args, **opts, &b|
              block.call(self, m, *args, **opts, &b)
            end
          end
        end
      end

      def method_list(type = nil)
        if type && ::SimpleFeed::Providers::PROVIDER_METHODS.key?(type.to_sym)
          ::SimpleFeed::Providers::PROVIDER_METHODS[type.to_sym]
        else
          ::SimpleFeed::Providers::REQUIRED_METHODS
        end
      end
    end
  end
end

require_relative 'providers/hash'
require_relative 'providers/redis'
