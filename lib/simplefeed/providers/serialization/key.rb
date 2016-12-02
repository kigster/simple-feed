require 'base62-rb'

module SimpleFeed
  module Providers
    module Serialization
      class Key
        attr_accessor :user_id, :compacted_id, :namespace

        def initialize(user_id, namespace = nil)
          self.user_id      = user_id
          self.compacted_id =::Base62.encode(user_id)
          self.namespace    = namespace ? "#{namespace}|" : ''
        end

        def data
          @data ||= "#{prefix}.d"
        end

        def meta
          @meta ||= "#{prefix}.m"
        end

        def for(type)
          "#{prefix}.#{type.to_s}"
        end

        def to_s
          data
        end

        private

        def prefix
          @prefix ||= "#{namespace}u.#{compacted_id}"
        end

      end
    end
  end
end

