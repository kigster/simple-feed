require 'forwardable'
require_relative 'base'

module SimpleFeed
  module Activity
    class MultiUser < Base

      extend Forwardable
      def_delegators :user_ids, :size, :each, :select, :delete_if, :inject

      attr_reader :user_ids

      include Enumerable

      #
      # Multi-user API for the feeds.
      #
      # ```ruby
      # @multi = SimpleFeed.get(:feed_name).for(User.active.map(&:id))
      #
      # @multi.store(value:, at:)
      # @multi.store(event:)
      # # => [Response] { user_id => [Boolean], ... } true if the value was stored, false if it wasn't.
      #
      # @multi.delete(value:, at:)
      # @multi.delete(event:)
      # # => [Response] { user_id => [Boolean], ... } true if the value was deleted, false if it didn't exist
      #
      # @multi.wipe
      # # => [Response] { user_id => [Boolean], ... } true if user activity was found and deleted, false otherwise
      #
      # @multi.paginate(page:, per_page:, peek: false)
      # # => [Response] { user_id => [Array]<Event>, ... }
      #
      # # With (peak: true) does not reset last_read, otherwise it does.
      #
      # @multi.fetch
      # # => [Response] { user_id => [Array]<Event>, ... }
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
      # ```

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
