# frozen_string_literal: true

require_relative 'base'

module SimpleFeed
  module Activity
    # Lazy implementation of SingleUser based on delegating an array of
    # one consumer_id to +MultiUser+

    class SingleUser < ::SimpleFeed::Activity::Base
      attr_reader :consumer_id
      attr_accessor :user_activity

      include Enumerable

      def each
        yield(consumer_id)
      end

      # ```ruby
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
      #  @activity.delete_if do |consumer_id, event|
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
      #  #   with_total: true — returns a hash for each consumer_id:
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
        unless response.has_user?(instance.consumer_id)
          raise StandardError, "Nil response from provider #{instance.feed.provider&.provider&.class}, method #{method}(#{opts}) — consumer_id #{instance.consumer_id}"
        end

        response = response[instance.consumer_id]
        block&.call(response)
        response
      end

      def initialize(consumer_id:, feed:)
        @feed = feed
        @consumer_id = consumer_id
        self.user_activity = MultiUser.new(feed: feed, consumer_ids: [consumer_id])
      end
    end
  end
end
