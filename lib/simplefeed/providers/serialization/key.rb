require 'base62-rb'
require 'hashie/mash'
require 'liquid'
module SimpleFeed
  module Providers
    module Serialization
      class Key
        attr_accessor :user_id, :namespace
        attr_accessor :base62_user_id, :key_types, :template

        # Here is a meta key for a given user ID:
        #
        #            user   'm' for meta
        #              ↓        ↓
        #          "ff|u.f23098.m"
        #           ↑         ↑
        #         namespace user_id(base62)
        #

        TEMPLATE = Liquid::Template.parse(
          %Q[{%- if namespace != null and namespace != '' -%}{{ namespace | append: '|'}}{%- endif -%}u.{{ base62_user_id }}.{{ key_type }}]
        )

        def initialize(user_id, namespace = nil, key_types = %i(meta data), template = TEMPLATE)
          self.namespace = namespace
          self.key_types = key_types
          self.user_id   = user_id
          self.template  = template

          self.base62_user_id = ::Base62.encode(user_id)

          key_types.each do |type|
            unless self.class.respond_to?(type)
              self.class.send(:define_method, type) do
                instance_variable_get("@#{type}") || instance_variable_set("@#{type}", render_key(type))
              end
            end
          end
        end

        def render_key(type)
          template.render('namespace'      => namespace.to_s,
                          'base62_user_id' => base62_user_id,
                          'key_type'       => type.to_s[0])
        end

        def to_s
          super + { user_id: user_id, base62_user_id: base62_user_id, key_types: key_types }.to_s
        end

        def inspect
          super
        end

        def keys
          key_types.map { |t| self.send(t) }.sort
        end
      end
    end
  end
end

