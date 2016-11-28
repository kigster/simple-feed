module SimpleFeed
  module Providers
    REQUIRED_METHODS = %i(store remove wipe reset_last_read last_read paginate all total_count unread_count)

    def self.define_provider_methods(klass, prefix = nil, &block)
      # Methods on the class instance
      klass.class_eval do
        SimpleFeed::Providers::REQUIRED_METHODS.each do |m|
          method_name = prefix ? "#{prefix}_#{m.to_s}".to_sym : m
          define_method(method_name) do |*args, **opts|
            block.call(self, m, *args, **opts)
          end
        end
      end
    end
  end
end

require_relative 'providers/base_provider'
