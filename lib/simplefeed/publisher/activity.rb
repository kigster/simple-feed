# frozen_string_literal: true

require 'forwardable'
require 'simplefeed/providers'

module SimpleFeed
  module Publisher
    class Activity
      attr_reader :feed, :consumers

      extend Forwardable
      include Enumerable

      include Providers::PublisherMethods

      def_delegators :@consumers, :size, :each, :select, :delete_if, :inject

      def initialize(feed:, consumers:)
        @feed = feed
        @consumers = consumers
      end
    end
  end
end

