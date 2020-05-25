# frozen_string_literal: true

require 'base62-rb'
require 'hashie/mash'

module SimpleFeed
  module Providers
    # Here is a meta key for a given user ID:
    #
    #            user   'm' for meta
    #              ↓        ↓
    #          "ff|u.f23098.m"
    #           ↑         ↑
    #         namespace consumer(base62)
    #
    class Key
      class << self
        def rot13(value)
          value.tr('abcdefghijklmnopqrstuvwxyz',
                   'nopqrstuvwxyzabcdefghijklm')
        end
      end

      SERIALIZED_DATA_TEMPLATE = '{{namespace}}u.{{data_id}}.d'
      SERIALIZED_META_TEMPLATE = '{{namespace}}u.{{meta_id}}.m'

      attr_reader :consumer, :namespace, :data_key_transformer, :meta_key_transformer

      def initialize(consumer,
                     namespace: nil,
                     data_key_transformer: nil,
                     meta_key_transformer: nil)
        @consumer = consumer
        @namespace = namespace
        @data_key_transformer = data_key_transformer
        @meta_key_transformer = meta_key_transformer
      end

      def data
        @data ||= render(SERIALIZED_DATA_TEMPLATE)
      end

      def meta
        @meta ||= render(SERIALIZED_META_TEMPLATE)
      end

      def keys
        [data, meta]
      end

      def to_s
        super + key_params.to_s
      end

      def inspect
        super + key_params.inspect
      end

      private

      def render(template)
        template.dup.tap do |output|
          key_params.each_pair do |key, value|
            output.gsub!(/{{#{key}}}/, value.to_s)
          end
        end
      end

      def obscure_value(id)
        id = id.to_i if id.is_a?(String) && /^[\d]+$/.match?(id)

        if id.is_a?(Numeric)
          ::Base62.encode(id)
        else
          self.class.rot13(id.to_s)
        end
      end

      def key_params
        @key_params ||= Hashie::Mash.new(
          namespace: namespace ? "#{namespace}|" : '',
          data_id:   obscure_value(data_id),
          meta_id:   obscure_value(meta_id)
        )
      end

      def meta_id
        meta_key_transformer&.call(consumer) || consumer
      end

      def data_id
        data_key_transformer&.call(consumer) || consumer
      end
    end
  end
end
