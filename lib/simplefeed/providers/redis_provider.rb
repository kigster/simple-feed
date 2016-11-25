require 'redis'
require 'simplefeed/providers/base_provider'
require_relative 'redis/driver'
require 'base62-rb'

module SimpleFeed
  module Providers
    # Internal data structure:
    #
    #   ```YAML
    #     u.afkj234.data:
    #       - [ 'John liked Robert', '2016-11-20 23:32:56 -0800' ]
    #       - [ 'Debbie liked Robert', '2016-11-20 23:35:56 -0800' ]
    #     u.afkj234.meta: { total: 2, unread: 2, last_read: 2016-11-20 22:00:34 -08:00 GMT }
    #   ```
    class RedisProvider < ::SimpleFeed::Providers::BaseProvider

      SimpleFeed::Providers.define_provider_methods(self) do |provider, method, **opts, &block|
        user = User.new(feed: provider.feed, user_id: opts.delete(:user_id))
        opts.empty? ?
          user.send(method, &block) :
          user.send(method, **opts, &block)
      end

      class User
        include SimpleFeed::Providers::Redis::Driver
        attr_reader :feed, :user_id, :id

        def initialize(feed:, user_id:)
          @feed    = feed
          @user_id = user_id
          @id      = ::Base62.encode(user_id)
        end

        def store(value:, at:)

        end

        def remove(value:, at: nil)
        end

        def wipe
        end

        def paginate(page:, per_page: feed.per_page)
          []
        end

        def all
          []
        end

        def reset_last_read
        end

        def count
        end

        def unread_count
        end

        def last_read
        end

      end

    end
  end
end
