module SimpleFeed
  class MultiUserActivity
    attr_reader :feed, :user_ids

    include Enumerable

    def each
      self.user_ids.each{ |id| yield(id) }
    end

    #
    # Single-user API for the feeds.
    #
    # ```ruby
    # @multi = SimpleFeed.get(:feed_name).multi_user_activity(User.active.map(&:id))
    #
    # @multi.store(value:, at:)
    # @multi.store(event:)
    # # => [Response] { user_id => [Boolean], ... } true if the value was stored, false if it wasn't.
    #
    # @multi.remove(value:, at:)
    # @multi.remove(event:)
    # # => [Response] { user_id => [Boolean], ... } true if the value was removed, false if it didn't exist
    #
    # @multi.wipe
    # # => [Response] { user_id => [Boolean], ... } true if user activity was found and deleted, false otherwise
    #
    # @multi.paginate(page:, per_page:, peek: false)
    # # => [Response] { user_id => [Array]<Event>, ... }
    #
    # # With (peak: true) does not reset last_read, otherwise it does.
    #
    # @multi.all
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
      response = instance.feed.send(method, **opts, &block)
      yield(response) if block_given?
      raise StandardError, "Nil response from provider #{instance.feed.provider&.provider&.class}, method #{method}(#{opts})" unless response
      response
    end

    def initialize(feed:, user_ids:)
      @user_ids = user_ids
      @feed     = feed
    end


  end
end
