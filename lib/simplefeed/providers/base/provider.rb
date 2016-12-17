require 'simplefeed/providers/key'

module SimpleFeed
  module Providers
    class NotImplementedError < ::StandardError
      def initialize(klass, method)
        super("Class #{klass.name} did not implement abstract method #{method}, but was called.")
      end
    end

    module Base
      class Provider
        attr_accessor :feed

        def self.class_to_registry(klass)
          klass.name.split('::').delete_if { |n| %w(SimpleFeed Providers Provider).include?(n) }.compact.last.downcase.to_sym
        end

        def self.inherited(klass)
          SimpleFeed::Providers.register(class_to_registry(klass), klass)
        end

        # SimpleFeed::Providers::REQUIRED_METHODS.each do |m|
        #   define_method(m) do |*|
        #     raise ::SimpleFeed::Providers::NotImplementedError.new(self, m)
        #   end
        # end

        protected

        def tap(value)
          yield
          value
        end

        def key(user_id)
          feed.key(user_id)
        end

        def to_array(user_ids)
          user_ids.is_a?(Array) ? user_ids : [user_ids]
        end

        def batch_size
          feed.batch_size
        end

        def with_response_batched(user_ids, external_response = nil)
          with_response(external_response) do |response|
            batch(user_ids) do |key|
              response.for(key.user_id) { yield(key, response) }
            end
          end
        end

        def batch(user_ids)
          to_array(user_ids).each_slice(batch_size) do |batch|
            batch.each do |user_id|
              yield(key(user_id))
            end
          end
        end

        def with_response(response = nil)
          response ||= SimpleFeed::Response.new
          yield(response)
          if self.respond_to?(:transform_response)
            response.transform do |user_id, result|
              # calling into a subclass
              transform_response(user_id, result)
            end
          end
          response
        end

        def with_result
          result = yield
          result = transform_response(nil, result) if self.respond_to?(:transform_response)
          result
        end
      end
    end
  end
end
