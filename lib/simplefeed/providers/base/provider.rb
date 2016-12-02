require 'simplefeed/providers/serialization/key'

module SimpleFeed
  module Providers
    module Base

      class Provider
        attr_accessor :feed

        def self.class_to_registry(klass)
          klass.name.split('::').delete_if { |n| %w(SimpleFeed Providers Provider).include?(n) }.compact.first.downcase.to_sym
        end

        def self.inherited(klass)
          SimpleFeed::Providers.register(class_to_registry(klass), klass)
        end

        public

        # TODO: single user delegator
        #
        # SimpleFeed::Providers.define_provider_methods(self) do |base, method, *args, **opts|
        #   user_ids = opts.delete(:user_ids)
        #   base.single_user_delegator(method, user_ids, **opts)
        # end
        #
        # def single_user_delegator(method, user_ids, **opts)
        #   single_user_method = "#{method}_1u".to_sym
        #   if self.respond_to?(single_user_method)
        #     with_response_batched(method, user_ids) do |key, response|
        #       response.for(key.user_id) do
        #         self.send(single_user_method, key.user_id, **opts)
        #       end
        #     end
        #   else
        #     raise ProviderMethodNotImplementedError, method
        #   end
        # end

        protected

        def key(user_id)
          ::SimpleFeed::Providers.key(user_id, feed.namespace)
        end

        def time_to_score(at)
          (1000 * at.to_f).to_i
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
      end
    end
  end
end
