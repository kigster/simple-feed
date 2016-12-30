require 'redis'
require 'base62-rb'
require 'forwardable'
require 'redis/pipeline' # defines Redis::Future

require 'simplefeed/providers/base/provider'
require 'simplefeed/providers/key'

require_relative 'driver'
require_relative 'stats'

module SimpleFeed
  module Providers
    module Redis
      # Internal data structure:
      #
      #   ```YAML
      #     u.afkj234.data:
      #       - [ 'John liked Robert', '2016-11-20 23:32:56 -0800' ]
      #       - [ 'Debbie liked Robert', '2016-11-20 23:35:56 -0800' ]
      #     u.afkj234.meta: { total: 2, unread: 2, last_read: 2016-11-20 22:00:34 -08:00 GMT }
      #   ```
      class Provider < ::SimpleFeed::Providers::Base::Provider

        # SimpleFeed::Providers.define_provider_methods(self) do |provider, method, **opts, &block|
        #   users = Users.new(provider: provider, user_ids: opts.delete(:user_ids))
        #   opts.empty? ?
        #     users.send(method, &block) :
        #     users.send(method, **opts, &block)
        # end
        #

        include Driver

        def store(user_ids:, value:, at: Time.now)
          with_response_pipelined(user_ids) do |redis, key|
            tap redis.zadd(key.data, at.to_f, value) do
              redis.zremrangebyrank(key.data, 0, -feed.max_size - 1)
            end
          end
        end

        def delete(user_ids:, value:, **)
          with_response_pipelined(user_ids) do |redis, key|
            redis.zrem(key.data, value)
          end
        end

        def delete_if(user_ids:)
          raise ArgumentError, '#delete_if must be called with a block that receives (user_id, event) as arguments.' unless block_given?
          with_response_batched(user_ids) do |key|
            fetch(user_ids: [key.user_id])[key.user_id].map do |event|
              with_redis do |redis|
                if yield(event, key.user_id)
                  redis.zrem(key.data, event.value) ? event : nil
                end
              end
            end.compact
          end
        end

        def wipe(user_ids:)
          with_response_pipelined(user_ids) do |redis, key|
            key.keys.all? { |redis_key| redis.del(redis_key) }
          end
        end

        def paginate(user_ids:, page:,
                     per_page: feed.per_page,
                     with_total: false,
                     reset_last_read: false)

          reset_last_read_value(user_ids: user_ids, at: reset_last_read) if reset_last_read

          with_response_pipelined(user_ids) do |redis, key|
            events = paginated_events(page, per_page, redis, key)
            with_total ? { events:      events,
                           total_count: redis.zcard(key.data) } : events
          end
        end

        def fetch(user_ids:, since: nil, reset_last_read: false)
          if since == :unread
            last_read_response = with_response_pipelined(user_ids) do |redis, key|
              get_users_last_read(redis, key)
            end
          end

          response = with_response_pipelined(user_ids) do |redis, key|
            if since == :unread
              redis.zrevrangebyscore(key.data, '+inf', (last_read_response.delete(key.user_id) || 0).to_f, withscores: true)
            elsif since
              redis.zrevrangebyscore(key.data, '+inf', since.to_f, withscores: true)
            else
              redis.zrevrange(key.data, 0, -1, withscores: true)
            end
          end

          reset_last_read_value(user_ids: user_ids, at: reset_last_read) if reset_last_read

          response
        end

        def reset_last_read(user_ids:, at: Time.now)
          with_response_pipelined(user_ids) do |redis, key, *|
            reset_users_last_read(redis, key, at.to_f)
          end
        end

        def total_count(user_ids:)
          with_response_pipelined(user_ids) do |redis, key|
            redis.zcard(key.data)
          end
        end

        def unread_count(user_ids:)
          response = with_response_pipelined(user_ids) do |redis, key|
            get_users_last_read(redis, key)
          end
          with_response_pipelined(response.user_ids, response) do |redis, key, _response|
            last_read = _response.delete(key.user_id).to_f
            redis.zcount(key.data, last_read, '+inf')
          end
        end

        def last_read(user_ids:)
          with_response_pipelined(user_ids) do |redis, key, *|
            get_users_last_read(redis, key)
          end
        end

        FEED_METHODS = %i(total_memory_bytes total_users last_disk_save_time)

        def total_memory_bytes
          with_stats(:used_memory_since_boot)
        end

        def total_users
          with_redis { |redis| redis.dbsize / 2 }
        end

        def with_stats(operation)
          with_redis do |redis|
            SimpleFeed::Providers::Redis::Stats.new(redis).send(operation)
          end
        end

        def transform_response(user_id = nil, result)
          case result
            when ::Redis::Future
              transform_response(user_id, result.value)

            when ::Hash

              if result.values.any? { |v| transformable_type?(v) }
                result.each { |k, v| result[k] = transform_response(user_id, v) }
              else
                result
              end

            when ::Array

              if result.any? { |v| transformable_type?(v) }
                result = result.map { |v| transform_response(user_id, v) }
              end

              if result.size == 2 && result[1].is_a?(Float)
                SimpleFeed::Event.new(value: result[0], at: Time.at(result[1]))
              else
                result
              end

            when ::String
              if result =~ /^\d+\.\d+$/
                result.to_f
              elsif result =~ /^\d+$/
                result.to_i
              else
                result
              end
            else
              result
          end
        end

        def transformable_type?(value)
          [
            ::Redis::Future,
            ::Hash,
            ::Array,
            ::String
          ].include?(value.class)
        end

        private

        #——————————————————————————————————————————————————————————————————————————————————————
        # helpers
        #——————————————————————————————————————————————————————————————————————————————————————

        def reset_users_last_read(redis, key, time = nil)
          time = time.nil? ? Time.now.to_f : time.to_f
          redis.hset(key.meta, 'last_read', time)
          Time.at(time)
        end

        # returns a string containing a float, which must then be
        # converted into float in #transform
        def get_users_last_read(redis, key)
          redis.hget(key.meta, 'last_read')
        end

        def paginated_events(page, per_page, redis, key)
          redis.zrevrange(key.data, (page - 1) * per_page, page * per_page - 1, withscores: true)
        end

        #——————————————————————————————————————————————————————————————————————————————————————
        # Operations with response
        #——————————————————————————————————————————————————————————————————————————————————————

        def with_response_pipelined(user_ids, response = nil)
          with_response(response) do |response|
            batch_pipelined(user_ids) do |redis, key|
              response.for(key.user_id) { yield(redis, key, response) }
            end
          end
        end

        def with_response_multi(user_ids, response = nil)
          with_response(response) do |response|
            batch_multi(user_ids) do |redis, key|
              response.for(key.user_id) { yield(redis, key, response) }
            end
          end
        end

        #——————————————————————————————————————————————————————————————————————————————————————
        # Batch operations
        #——————————————————————————————————————————————————————————————————————————————————————
        def batch_pipelined(user_ids)
          to_array(user_ids).each_slice(batch_size) do |batch|
            with_pipelined do |redis|
              batch.each do |user_id|
                yield(redis, key(user_id))
              end
            end
          end
        end

        def batch_pipelined_multi(user_ids)
          to_array(user_ids).each_slice(batch_size) do |batch|
            with_pipelined do
              batch.each do |user_id|
                with_multi do |redis|
                  yield(redis, key(user_id))
                end
              end
            end
          end
        end

        def batch_multi(user_ids)
          to_array(user_ids).each_slice(batch_size) do |batch|
            batch.each do |user_id|
              with_multi do |redis|
                yield(redis, key(user_id))
              end
            end
          end
        end
      end
    end
  end
end
