# frozen_string_literal: true

require 'forwardable'
require 'simplefeed/providers'

module SimpleFeed
  module Consumer
    class EventFeed
      attr_reader :feed, :consumers

      extend Forwardable
      include Enumerable

      include Providers::ConsumerMethods

      def_delegators :@consumers, :size, :each, :select, :delete_if, :inject

      def initialize(feed:, consumers:)
        @feed = feed
        @consumers = consumers
      end

    end
  end
end

