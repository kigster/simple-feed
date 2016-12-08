require 'base62-rb'
require 'hashie/mash'
module SimpleFeed
  module Providers
    module Serialization
      class Key
        attr_accessor :user_id, :short_id, :prefix, :config

        # This hash defines the paramters for the strategy we use
        # to create a compact key based on the user id, feed's namespace,
        # and the functionality, such as 'm' meta — as a hash for storing
        # arbitrary values (in particular, +last_read+). and 'd' data —
        # as a sorted set in for storing the actual events.
        #
        # ### Examples
        #
        # Here is a meta key for a given user ID:
        #
        #            user   'm' for meta
        #              ↓        ↓
        #          "ff|u.f23098.m"
        #           ↑         ↑
        #         namespace user_id(base62)
        #
        KEY_CONFIG = Hashie::Mash.new({
                                        separator:         '.',
                                        prefix:            '',
                                        namespace_divider: '|',
                                        namespace:         nil,
                                        primary:           ->(user_id) { ::Base62.encode(user_id) },
                                        primary_marker:    'u',
                                        secondary_markers: {
                                          data: 'd',
                                          meta: 'm'
                                        }
                                      })

        def initialize(user_id, namespace = nil, optional_key_config = {})
          optional_key_config.merge!(namespace: namespace) if namespace
          self.config = KEY_CONFIG.dup.merge!(optional_key_config)

          self.user_id  = user_id
          self.short_id = config.primary[user_id]

          self.prefix = configure_prefix

          config.secondary_markers.each_pair do |type, character|
            self.class.send(:define_method, type) do
              instance_variable_get("@#{type}") || instance_variable_set("@#{type}", "#{prefix}#{config.separator}#{character}")
            end
          end
        end

        def keys
          config.secondary_markers.map { |k, v| [k, self.send(k)] }
        end

        def for(type)
          "#{prefix}#{config.separator}#{type.to_s}"
        end

        def to_s
          super.gsub(/SimpleFeed::Providers::Serialization/, '...*') + { user_id: user_id, short_id: short_id, keys: keys }.to_json
        end

        def inspect

        end

        private

        # eg. ff|u.123498
        def configure_prefix
          namespace = config.namespace ? "#{config.namespace}#{config.namespace_divider}" : ''
          "#{namespace}#{config.primary_marker}#{config.separator}#{short_id}"
        end

      end
    end
  end
end

