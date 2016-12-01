require_relative 'base'

module SimpleFeed
  module Activity

    # Lazy implementation of SingleUser based on delegating an array of
    # one user_id to +MultiUser+

    class SingleUser < ::SimpleFeed::Activity::Base
      attr_reader :user_id
      attr_accessor :user_activity

      #
      # Single-user API for the feeds.
      #
      # @ua = SimpleFeed.get(:feed_name).user_activity(current_user.id)
      #
      # @ua.store(value:, at:)
      # # => [Boolean] true if the value was stored, false if it wasn't.
      #
      # @ua.delete(value:, at:)
      # # => [Boolean] true if the value was deleted, false if it didn't exist
      #
      # @ua.wipe
      # # => [Boolean] true
      #
      # @ua.paginate(page:, per_page:, peek: false)
      # # => [Array]<Event>
      # # with peak: true does not reset last_read
      #
      # @ua.fetch
      # # => [Array]<Event>
      #
      # @ua.reset_last_read
      # # => [Time] last_read
      #
      # @ua.total_count
      # # => [Integer] total_count
      #
      # @ua.unread_count
      # # => [Integer] unread_count
      #
      # @ua.last_read
      # # => [Time] last_read
      # ```

      SimpleFeed::Providers.define_provider_methods(self) do |instance, method, *args, **opts, &block|
        response = instance.user_activity.send(method, *args, **opts, &block)
        unless response.has_user?(instance.user_id)
          raise StandardError, "Nil response from provider #{instance.feed.provider&.provider&.class}, method #{method}(#{opts}) — user_id #{instance.user_id}"
        end
        response = response[instance.user_id]
        yield(response) if block_given?
        response
      end

      def initialize(user_id:, feed:)
        @feed              = feed
        @user_id           = user_id
        self.user_activity = MultiUser.new(feed: feed, user_ids: [user_id])
      end

    end
  end
end
