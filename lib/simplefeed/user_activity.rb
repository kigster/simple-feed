module SimpleFeed
  class UserActivity
    attr_reader :feed, :user_id
    attr_accessor :response

    SimpleFeed::Providers.define_provider_methods(self) do |instance, method, opts, &block|
      instance.response = nil
      opts.merge!(user_ids: [instance.user_id])
      if opts[:event]
        opts.merge!(value: opts[:event].value, at: opts[:event].at)
        opts.delete(:event)
      end
      instance.response = instance.feed.send(method, **opts, &block)
      if instance.response then
        instance.response[instance.user_id]
      else
        raise StandardError, "Nil response from provider #{instance.feed.provider&.provider&.class}, method #{method}(#{opts})"
      end


    end

    def initialize(user_id:, feed:)
      @user_id  = user_id
      @feed     = feed
      @response = nil
    end

  end
end
