require_relative 'providers'
require 'simplefeed'
require_relative 'dsl/activities'

module SimpleFeed
  # This module offers a convenient DSL-based approach to manipulating user feeds.
  #
  # Usage:
  #
  #     require 'simplefeed/dsl'
  #     include SimpleFeed::DSL
  #
  #     with_activity(SimpleFeed.get(:newsfeed).activity(user_id)) do
  #       store(value: 'hello', at: Time.now)  #=> true
  #       fetch                                # => [ Event, Event, ... ]
  #       total_count                          # => 12
  #       unread_count                         # => 4
  #     end
  #
  module DSL
    class << self
      attr_accessor :debug

      def debug?
        self.debug
      end
    end

    def with_activity(activity, **opts, &block)
      opts.merge!({ context: self }) unless opts && opts[:context]
      SimpleFeed::DSL::Activities.new(activity, **opts).instance_eval(&block)
    end

    def event(value, at = Time.now)
      SimpleFeed::Event.new(value, at)
    end
  end
end
