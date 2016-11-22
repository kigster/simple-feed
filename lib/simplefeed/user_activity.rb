module SimpleFeed
  class UserActivity
    attr_reader :feed, :user_id

    SimpleFeed::Providers.define_provider_methods(self) do |instance, method, opts, &block|
      opts.merge!(user_id: instance.user_id)
      if opts[:event]
        opts.merge!(value: opts[:event].value, at: opts[:event].at)
        opts.delete(:event)
      end
      instance.feed.send(method, **opts, &block)
    end

    def initialize(user_id:, feed:)
      @user_id = user_id
      @feed    = feed
      @events  = nil
    end

    # @param [Integer] page either nil or an Integer value greater than zero
    def events(page: nil, per_page: feed.per_page, &block)
      @events ||= feed.all(user_id: user_id)
      self.class.order_events(@events, &block)
      (page && page > 0) ? @events[((page - 1) * per_page)...(page * per_page)] : @events
    end

    def self.order_events(events, &block)
      return nil unless events
      events.sort! do |a, b|
        block ? yield(a, b) : b.at <=> a.at
      end
    end

  end

end
