require 'forwardable'
require_relative 'base'

module SimpleFeed
  module Activity
    class MultiUser < Base

      attr_reader :user_ids

      extend Forwardable
      def_delegators :@user_ids, :size, :each, :select, :delete_if, :inject

      include Enumerable

      #
      # API Examples
      # ============
      #
      #```ruby
      # @multi = SimpleFeed.get(:feed_name).activity(User.active.map(&:id))
      #
      # @multi.store(value:, at:)
      # @multi.store(event:)
      # # => [Response] { user_id => [Boolean], ... } true if the value was stored, false if it wasn't.
      #
      # @multi.delete(value:, at:)
      # @multi.delete(event:)
      # # => [Response] { user_id => [Boolean], ... } true if the value was removed, false if it didn't exist
      #
      # @multi.delete_if do |event, user_id|
      #   # if the block returns true, the event is deleted and returned
      # end
      # # => [Response] { user_id => [Array]<Event>, ... }
      #
      # @multi.wipe
      # # => [Response] { user_id => [Boolean], ... } true if user activity was found and deleted, false otherwise
      #
      # @multi.paginate(page:, per_page:, reset_last_read: [Bool | Time], with_total: false)
      # # => [Response] { user_id => [Array]<Event>, ... }
      # # Options:
      # #   reset_last_read: false — reset last read to Time.now (true), or provided timestamp
      # #   with_total: true — returns a hash for each user_id:
      # #        => [Response] { user_id => { events: Array<Event>, total_count: 3 }, ... }
      #
      # # Return un-paginated list of all items, optionally filtered
      # @multi.fetch(since: nil, reset_last_read: [Bool | Time] )
      # # => [Response] { user_id => [Array]<Event>, ... }
      # # Options:
      # #   reset_last_read: false — reset last read to Time.now (true), or provided timestamp
      # #   since: <timestamp> — if provided, returns all items posted since then
      # #   since: :unread — if provided, returns all unread items
      #
      # @multi.reset_last_read
      # # => [Response] { user_id => [Time] last_read, ... }
      #
      # @multi.total_count
      # # => [Response] { user_id => [Integer] total_count, ... }
      #
      # @multi.unread_count
      # # => [Response] { user_id => [Integer] unread_count, ... }
      #
      # @multi.last_read
      # # => [Response] { user_id => [Time] last_read, ... }
      #
      #```

      SimpleFeed::Providers.define_provider_methods(self) do |instance, method, *args, **opts, &block|
        opts.merge!(user_ids: instance.user_ids)
        if opts[:event]
          opts.merge!(value: opts[:event].value, at: opts[:event].at)
          opts.delete(:event)
        end
        response = instance.feed.send(method, *args, **opts, &block)
        yield(response) if block_given?
        raise StandardError, "Nil response from provider #{instance.feed.provider&.provider&.class}, method #{method}(#{opts})" unless response
        response
      end

      def initialize(feed:, user_ids:)
        super(feed: feed)
        @user_ids = user_ids
      end
    end
  end
end
