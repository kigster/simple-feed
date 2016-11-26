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

        def store(user_ids:, value:, at:)
          with_response(:store) do |response|
            batch_multi(user_ids) do |redis, k|
              response.for(k.user_id) {
                { added_count:  redis.zadd(k.data, -(1000.0 * at.to_f).to_i, value),
                  total_count:  redis.hget(k.meta, 'total_count'),
                  unread_count: redis.hget(k.meta, 'unread_count'),
                }
              }
            end

            batch_multi(user_ids) do |redis, k|
              h  = response[k.user_id]
              ac = h[:added_count].value ? 1 : 0
              tc = h[:total_count].value.to_i
              if tc >= feed.max_size
                h[:removed_count] = redis.zremrangebyrank(k.data, -feed.max_size - 1, -1) ? 1 : 0
              else
                h[:total_count]  = redis.hincrby(k.meta, 'total_count', ac)
                h[:unread_count] = redis.hincrby(k.meta, 'unread_count', ac)
              end
              h[:added_count] = ac
              response.for(k.user_id) { h }
            end
          end
        end

        def remove(user_ids:, value:, **)
          resp = with_response(:remove) do |response|
            batch(user_ids) do |k|
              with_pipelined do |redis|
                response.for(k.user_id) do
                  { did_remove:   redis.zrem(k.data, value),
                    timestamp:    redis.zscore(k.data, value),
                    last_read:    redis.hget(k.meta, 'last_read'),
                    unread_count: redis.hget(k.meta, 'unread_count'),
                    total_count:  redis.hget(k.meta, 'total_count') }
                end
              end

              with_multi do |redis|
                h = response[k.user_id]
                h.each { |k, v| h[k] = v.value }

                tc = h[:total_count].to_i || 0
                uc = h[:unread_count].to_i || 0
                lr = h[:last_read].to_i || 0
                ts = h[:timestamp].to_i || 0

                did_remove   = h[:did_remove]
                remove_count = did_remove ? 1 : 0

                h.clear

                h[:total_count] = redis.hincrby(k.meta, 'total_count', -remove_count) if did_remove && tc > 0
                if did_remove && lr < ts && uc > 0
                  h[:unread_count] = redis.hincrby(key.meta, 'unread_count', -remove_count)
                end
                response.for(k.user_id) { h }
              end
            end
          end
          # pp resp
          resp
        end

        def update_meta(key, redis, total_count:, unread_count:)
          redis.hset(key, 'total_count', total_count)
          redis.hset(key, 'unread_count', unread_count)
        end


        def wipe(user_ids:)
          with_response_pipelined(:wipe, user_ids) do |redis, k|
            redis.hset(k.meta, 'total_count', 0)
            redis.hset(k.meta, 'unread_count', 0)
            redis.del(k.data)
          end
        end

        def paginate(user_ids:, page:, per_page: feed.per_page)
          with_response_pipelined(:paginate, user_ids) do |redis, key|
            redis.zrevrange(key.data, (page - 1) * per_page, page * per_page)
          end
        end

        def all(user_ids:)
          with_response_pipelined(:all, user_ids) do |redis, key|
            redis.zrevrange(key.data, 0, -1)
          end
        end

        def reset_last_read(user_ids:, at: Time.now)
          with_response_pipelined(:all, user_ids) do |redis, key|
            redis.hset(key.meta, 'last_read', time_to_score(at))
            at
          end
        end

        def total_count(user_ids:)
          fetch_meta(:total_count, user_ids)
        end

        def unread_count(user_ids:)
          fetch_meta(:unread_count, user_ids)
        end

        def last_read(user_ids:)
          fetch_meta(:last_read, user_ids)
        end

        def recalculate_counts(user_ids)
          batch_pipelined_multi(user_ids) do |redis, user_id|
            k = key(user_id)
            redis.hset(k.meta, 'total_count', redis.zcard(k.data))
          end
        end

        def map_response(result)
          # puts "checking #{result.class.name} — #{result.inspect}"
          case result
            when ::Redis::Future
              map_response(result.value)
            when Hash
              result.each { |k, v| result[k] = map_response(v) }
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

        def fetch_meta(name, user_ids)
          with_response_pipelined(name.to_sym, user_ids) do |redis, key|
            redis.hget(key.meta, name.to_s)
          end
        end

        def with_response_pipelined(operation, user_ids)
          with_response(operation) do |response|
            batch_pipelined(user_ids) do |redis, key|
              response.for(key.user_id) { yield(redis, key) }
            end
          end
        end

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
