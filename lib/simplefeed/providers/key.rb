require 'base62-rb'

module SimpleFeed
  module Providers
    class Key
      attr_accessor :user_id, :compacted_id, :namespace

      def initialize(user_id, namespace = nil)
        self.user_id      = user_id
        self.compacted_id =::Base62.encode(user_id)
        self.namespace    = namespace
      end

      def data
        ns "u.#{compacted_id}.d"
      end

      def meta
        ns "u.#{compacted_id}.m"
      end

      def for(type)
        ns "u.#{compacted_id}.#{type.to_s}"
      end

      def to_s
        data
      end

      private

      def ns(key)
        namespace ? "#{namespace}/#{key}" : key
      end

    end
  end
end
