module SimpleFeed
  class UserActivity
    attr_reader :feed, :user_id

    SimpleFeed::Providers::REQUIRED_METHODS.each do |m|
      define_method(m) do |*args, **opts, &block|
        opts.merge!(user_id: self.user_id)
        if opts[:event]
          opts.merge!(value: opts[:event].value, at: opts[:event].at)
          opts.delete(:event)
        end

        self.feed.send(m, *args, **opts, &block)
      end
    end

    def initialize(user_id:, feed: )
      @user_id      = user_id
      @feed         = feed
      @events       = nil
    end

    # @param [Integer] page either nil or an Integer value greater than zero
    def events(page: nil, per_page: feed.per_page, &block)
      @events ||= feed.all(user_id)
      self.class.order_events(@events, &block)
      (page && page > 0) ? @events[((page - 1) * per_page)...(page * per_page)] : @events
    end

    def self.order_events(events, &block)
      events.sort! do |a, b|
        block ? yield(a, b) : b.at <=> a.at
      end
    end

  end

end
