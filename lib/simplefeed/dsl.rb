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
  #       puts 'success' if store(value: 'hello', at: Time.now)
  #       puts fetch
  #       puts total_count
  #       puts unread_count
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
  end
end
