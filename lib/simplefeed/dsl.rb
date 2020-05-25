# frozen_string_literal: true

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
  #     with_activity(SimpleFeed.get(:newsfeed).event_feed(consumer_id)) do
  #       store(data: 'hello', at: Time.now)  #=> true
  #       fetch                                # => [ EventTuple, EventTuple, ... ]
  #       total_count                          # => 12
  #       unread_count                         # => 4
  #     end
  #
  module DSL
    class << self
      attr_accessor :debug

      def debug?
        debug
      end
    end

    def with_activity(activity, **opts, &block)
      opts.merge!({ context: self }) unless opts && opts[:context]
      SimpleFeed::DSL::Activities.new(activity, **opts).instance_eval(&block)
    end

    def event(value, at = Time.now)
      SimpleFeed::EventTuple.new(value, at)
    end
  end
end
