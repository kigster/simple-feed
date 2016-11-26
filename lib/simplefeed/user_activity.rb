module SimpleFeed
  class UserActivity
    attr_reader :feed, :user_ids

    SimpleFeed::Providers.define_provider_methods(self) do |instance, method, opts, &block|
      opts.merge!(user_ids: instance.user_ids)
      if opts[:event]
        opts.merge!(value: opts[:event].value, at: opts[:event].at)
        opts.delete(:event)
      end
      instance.feed.send(method, **opts, &block)
    end

    def initialize(user_ids:, feed:)
      @user_ids = user_ids
      @feed     = feed
    end

  end
end
