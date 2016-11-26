require 'redis'
require 'redis/connection/hiredis'
require 'connection_pool'
module SimpleFeed
  module Providers
    module Redis
      module Driver
        @enabled = true

        def self.enabled;  @enabled end
        def self.enable!;  @enabled = true; end
        def self.disable!; @enabled = false; end

        class Error < StandardError;
        end

        attr_accessor :pool

=begin

Various ways of defining a new Redis driver:

SimpleFeed::Redis::Driver.new(pool: ConnectionPool.new(size: 2) { Redis.new })
SimpleFeed::Redis::Driver.new(redis: -> { Redis.new }, pool_size: 2)
SimpleFeed::Redis::Driver.new(redis: Redis.new)
SimpleFeed::Redis::Driver.new(redis: { host: 'localhost', port: 6379, db: 1, timeout: 0.2 }, pool_size: 1)

=end
        def initialize(**opts)
          if opts[:pool] && opts[:pool].respond_to?(:with)
            self.pool = opts[:pool]

          elsif opts[:redis]
            redis      = opts[:redis]
            redis_proc = nil

            if redis.is_a?(Hash)
              redis_proc = -> { ::Redis.new(**opts[:redis]) }
            elsif redis.is_a?(Proc)
              redis_proc = redis
            elsif redis.is_a?(::Redis)
              redis_proc = -> { redis }
            end

            if redis_proc
              self.pool = ::ConnectionPool.new(size: (opts[:pool_size] || 2)) do
                redis_proc.call
              end
            end
          end

          raise ArgumentError, "Unable to construct Redis connection from arguments: #{opts.inspect}" unless self.pool && self.pool.respond_to?(:with)
        end

        %i(set get incr decr setex expire del setnx exists zadd zrange).each do |method|
          define_method(method) do |*args|
            self.exec method, *args
          end
        end

        alias_method :delete, :del
        alias_method :rm, :del
        alias_method :exists?, :exists

        def exec(redis_method, *args, **opts, &block)
          send_proc = redis_method if redis_method.respond_to?(:call)
          send_proc ||= ->(redis) { redis.send(redis_method, *args, &block) }

          if opts[:pipelined]
            opts.delete :pipelined
            with_pipelined { |redis| send_proc.call(redis) }
          else
            with { |redis| send_proc.call(redis) }
          end
        end

        class MockRedis
          def method_missing(name, *args, &block)
            puts "calling redis.#{name}(#{args.to_s.gsub(/[\[\]]/,'')}) { #{block ? block.call : nil} }"
          end
        end

        def with
          with_retries do
            pool.with do |redis|
              yield(redis)
            end
          end
        end

        def with_pipelined
          with_retries do
            with do |redis|
              redis.pipelined do
                yield(redis)
              end
            end
          end
        end

        def with_multi
          with_retries do
            with do |redis|
              redis.multi do
                yield(redis)
              end
            end
          end
        end

        def with_retries(tries = 3)
          yield(tries)
        rescue Errno::EINVAL => e
          on_error e
        rescue ::Redis::BaseConnectionError => e
          if (tries -= 1) > 0
            sleep rand(0..0.01)
            retry
          else
            on_error e
          end
        rescue ::Redis::CommandError => e
          (e.message =~ /loading/i || e.message =~ /connection/i) ? on_error(e) : raise(e)
        end

        def on_error(e)
          raise Error.new(e)
        end

      end
    end
  end
end