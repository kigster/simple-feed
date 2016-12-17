require_relative 'providers/key'
require_relative 'providers/proxy'

module SimpleFeed
  module Providers
    @registry = {}
    
    def self.registry
      @registry
    end
    
    def self.register(provider_name, provider_class)
      self.registry[provider_name] = provider_class
    end
    
    # These methods must be implemented by each Provider, and operation on a given
    # set of users passed via the user_ids: parameter.
    ACTIVITY_METHODS = %i(store delete delete_if wipe reset_last_read last_read paginate fetch total_count unread_count)

    # These methods must be implemented in order to gather statistics about each provider's
    # memory consumption and state.
    FEED_METHODS = %i(total_memory_bytes total_users)

    REQUIRED_METHODS = ACTIVITY_METHODS + FEED_METHODS

    def self.define_provider_methods(klass, prefix = nil, &block)
      # Methods on the class instance
      klass.class_eval do
        SimpleFeed::Providers::REQUIRED_METHODS.each do |m|
          method_name = prefix ? "#{prefix}_#{m.to_s}".to_sym : m
          define_method(method_name) do |*args, **opts, &b|
            block.call(self, m, *args, **opts, &b)
          end
        end
      end
    end
  end
end

require_relative 'providers/hash'
require_relative 'providers/redis'
