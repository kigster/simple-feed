# frozen_string_literal: true

require 'base62-rb'
require 'hashie/mash'
require 'simplefeed/key/template'
require 'simplefeed/key/type'

require 'forwardable'

module SimpleFeed
  module Providers
    # Here is a meta key for a given user ID:
    #
    #            user   'm' for meta
    #              ↓        ↓
    #          "ff|u.f23098.m"
    #           ↑         ↑
    #         namespace consumer_id(base62)
    #
    class Key
      attr_accessor :consumer_id, :key_template

      extend Forwardable
      def_delegators :@key_template, :key_names, :key_types

      def initialize(consumer_id, key_template)
        self.consumer_id = consumer_id
        self.key_template = key_template

        define_key_methods
      end

      # Defines #data and #meta methods.
      def define_key_methods
        key_template.key_types.each do |type|
          key_name = type.name
          next if respond_to?(key_name)

          self.class.send(:define_method, key_name) do
            instance_variable_get("@#{key_name}") ||
              instance_variable_set("@#{key_name}", type.render(render_options))
          end
        end
      end

      def serialized_consumer_id
        @serialized_consumer_id ||= if consumer_id.is_a?(Numeric)
                              ::Base62.encode(consumer_id)
                            else
                              rot13(consumer_id.to_s)
                            end
      end

      def keys
        key_names.map { |name| send(name) }
      end

      def render_options
        key_template.render_options.merge!({
                                             'consumer_id' => consumer_id,
                                             'serialized_consumer_id' => serialized_consumer_id
                                           })
      end

      def to_s
        super + { consumer_id: consumer_id, serialized_consumer_id: serialized_consumer_id, keys: keys }.to_s
      end

      def inspect
        render_options.inspect
      end

      private

      def rot13(value)
        value.tr('abcdefghijklmnopqrstuvwxyz',
                 'nopqrstuvwxyzabcdefghijklm')
      end
    end
  end
end
