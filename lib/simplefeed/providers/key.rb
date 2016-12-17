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
    #         namespace user_id(base62)
    #
    class Key
      attr_accessor :user_id, :key_template

      extend Forwardable
      def_delegators :@key_template, :key_names, :key_types

      def initialize(user_id, key_template)
        self.user_id  = user_id
        self.key_template = key_template

        define_key_methods
      end

      def define_key_methods
        key_template.key_types.each do |type|
          key_name = type.name
          unless self.respond_to?(key_name)
            self.class.send(:define_method, key_name) do
              instance_variable_get("@#{key_name}") ||
                instance_variable_set("@#{key_name}", type.render(render_options))
            end
          end

        end
      end

      def base62_user_id
        @base62_user_id ||= ::Base62.encode(user_id)
      end

      def keys
        key_names.map { |name| self.send(name) }
      end

      def render_options
        key_template.render_options.merge!({
                                             'user_id'        => user_id,
                                             'base62_user_id' => base62_user_id
                                           })
      end

      def to_s
        super + { user_id: user_id, base62_user_id: base62_user_id, keys: keys }.to_s
      end

      def inspect
        render_options.inspect
      end

      private

    end
  end
end

