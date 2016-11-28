require_relative 'multi_user_activity'

module SimpleFeed
  class SingleUserActivity
    attr_reader :user_id, :feed
    attr_accessor :multi_user_activity

    #
    # Single-user API for the feeds.
    #
    # @ua = SimpleFeed.get(:feed_name).user_activity(current_user.id)
    #
    # @ua.store(value:, at:)
    # # => [Boolean] true if the value was stored, false if it wasn't.
    #
    # @ua.remove(value:, at:)
    # # => [Boolean] true if the value was removed, false if it didn't exist
    #
    # @ua.wipe
    # # => [Boolean] true
    #
    # @ua.paginate(page:, per_page:, peek: false)
    # # => [Array]<Event>
    # # with peak: true does not reset last_read
    #
    # @ua.all
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
      response = instance.multi_user_activity.send(method, **opts)
      unless response.has_user?(instance.user_id)
        raise StandardError, "Nil response from provider #{instance.feed.provider&.provider&.class}, method #{method}(#{opts}) — user_id #{instance.user_id}"
      end
      response = response[instance.user_id]
      yield(response) if block_given?
      response
    end

    def initialize(user_id:, feed:)
      @feed                    = feed
      @user_id                 = user_id
      self.multi_user_activity = MultiUserActivity.new(feed: feed, user_ids: [user_id])
    end

  end
end
