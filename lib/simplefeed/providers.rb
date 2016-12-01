require_relative 'providers/serialization/key'
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
    
    def self.key(*args)
      SimpleFeed::Providers::Serialization::Key.new(*args)
    end
    
    REQUIRED_METHODS = %i(store delete delete_if wipe reset_last_read last_read paginate fetch total_count unread_count)

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

require_relative 'providers/base'
require_relative 'providers/hash'
require_relative 'providers/redis'
