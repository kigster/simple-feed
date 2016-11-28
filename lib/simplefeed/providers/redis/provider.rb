require 'redis'
require 'base62-rb'
require 'forwardable'
require 'redis/pipeline'

require 'simplefeed/providers/base_provider'
require 'simplefeed/providers/key'
require_relative 'driver'
require 'pp'
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
      class Provider < ::SimpleFeed::Providers::BaseProvider

        # SimpleFeed::Providers.define_provider_methods(self) do |provider, method, **opts, &block|
        #   users = Users.new(provider: provider, user_ids: opts.delete(:user_ids))
        #   opts.empty? ?
        #     users.send(method, &block) :
        #     users.send(method, **opts, &block)
        # end
        #

        include Driver
        @debug = false

        def self.debug?
          @debug
        end

        def store(user_ids:, value:, at:)
          response = with_response_pipelined(user_ids) do |redis, key|
            puts "zadd #{key.data} #{(1000.0 * at.to_f).to_i} '#{value}'" if self.class.debug?
            { a: redis.zadd(key.data, at.to_f, value),
              t: redis.zcard(key.data) }
          end
          with_response_pipelined(response.user_ids, response) do |redis, key, _response|
            puts _response[key.user_id].inspect if self.class.debug?
            total_count = _response[key.user_id][:t]
            add_result  = _response[key.user_id][:a]
            if total_count >= feed.max_size
              puts "zremrangebyrank #{key.data} #{-feed.max_size} -1" if self.class.debug?
              redis.zremrangebyrank(key.data, -feed.max_size - 1, -1)
            end
            add_result
          end
        end

        def remove(user_ids:, value:, **)
          with_response_pipelined(user_ids) do |redis, key|
            redis.zrem(key.data, value)
          end
        end

        def wipe(user_ids:)
          with_response_pipelined(user_ids) do |redis, key|
            redis.del(key.data)
          end
        end

        def paginate(user_ids:, page:, per_page: feed.per_page, peek: false, with_total: false)
          with_response_pipelined(user_ids) do |redis, key|
            redis.hset(key.meta, 'last_read', Time.now) unless peek
            _events = redis.zrevrange(key.data, (page - 1) * per_page, page * per_page, withscores: true)
            with_total ?
              { events:      _events,
                total_count: redis.zcard(key.data) } :
              _events
          end
        end

        def all(user_ids:)
          with_response_pipelined(user_ids) do |redis, key|
            redis.zrevrange(key.data, 0, -1)
          end
        end

        def reset_last_read(user_ids:, at: Time.now)
          with_response_pipelined(user_ids) do |redis, key, *|
            redis.hset(key.meta, 'last_read', time_to_score(at))
            at
          end
        end

        def total_count(user_ids:)
          with_response_pipelined(user_ids) do |redis, key|
            redis.zcard(key.data)
          end
        end

        def unread_count(user_ids:)
          response = with_response_pipelined(user_ids) do |redis, key|
            redis.hget(key.meta, 'last_read')
          end

          with_response_pipelined(response.user_ids, response) do |redis, key, _response|
            last_read = _response.delete(key.user_id).to_f
            redis.zcount(key.data, last_read, Time.now.to_f)
          end
        end

        def last_read(user_ids:)
          with_response_pipelined(user_ids) do |redis, key, *|
            redis.hget(key.meta, 'last_read')
          end
        end

        def transform_response(user_id, result)
          # puts "checking #{result.class.name} — #{result.inspect}"
          case result
            when ::Redis::Future
              transform_response(user_id, result.value)
            when Hash
              result.each { |k, v| result[k] = transform_response(user_id, v) }
            when Array
              if result.size == 2
                SimpleFeed::Event.new(*result)
              else
                result.map { |v| transform_response(user_id, v) }
              end
            when String
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

        private

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
