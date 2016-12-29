require_relative 'base'

module SimpleFeed
  module Activity

    # Lazy implementation of SingleUser based on delegating an array of
    # one user_id to +MultiUser+

    class SingleUser < ::SimpleFeed::Activity::Base
      attr_reader :user_id
      attr_accessor :user_activity

      include Enumerable

      def each
        yield(user_id)
      end

      #```ruby
      #  @activity = SimpleFeed.get(:feed_name).activity(current_user.id)
      #
      #  @activity.store(value:, at:)
      #  @activity.store(event:)
      #  # => [Boolean] true if the value was stored, false if it wasn't.
      #
      #  @activity.delete(value:, at:)
      #  @activity.delete(event:)
      #  # => [Boolean] true if the value was removed, false if it didn't exist
      #
      #  @activity.delete_if do |user_id, event|
      #    # if the block returns true, the event is deleted
      #  end
      #
      #  @activity.wipe
      #  # => [Boolean] true if user activity was found and deleted, false otherwise
      #
      #  @activity.paginate(page:, per_page:, reset_last_read: false, with_total: false)
      #  # => [Array]<Event>
      #  # Options:
      #  #   reset_last_read: false — reset last read to Time.now (true), or the provided timestamp
      #  #   with_total: true — returns a hash for each user_id:
      #  #        => { events: Array<Event>, total_count: 3 }
      #
      #  # Return un-paginated list of all items, optionally filtered
      #  @activity.fetch(since: nil, reset_last_read: false)
      #  # => [Array]<Event>
      #  # Options:
      #  #   reset_last_read: false — reset last read to Time.now (true), or the provided timestamp
      #  #   since: <timestamp> — if provided, returns all items posted since then
      #  #   since: :unread — if provided, returns all unread items
      #
      #  @activity.reset_last_read
      #  # => [Time] last_read
      #
      #  @activity.total_count
      #  # => [Integer] total_count
      #
      #  @activity.unread_count
      #  # => [Integer] unread_count
      #
      #  @activity.last_read
      #  # => [Time] last_read


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
