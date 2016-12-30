require 'redis'
require 'redis/connection/hiredis'
require 'connection_pool'
require 'colored2'
require 'hashie/mash'
require 'yaml'
require 'pp'

module SimpleFeed
  module Providers
    module Redis
      @debug = ENV['REDIS_DEBUG']

      def self.debug?
        self.debug
      end

      def self.with_debug(&block)
        previous_value                     = SimpleFeed::Providers::Redis.debug
        SimpleFeed::Providers::Redis.debug = true
        result                             = yield if block_given?
        SimpleFeed::Providers::Redis.debug = previous_value
        result
      end

      class << self
        attr_accessor :debug
      end

      module Driver
        class Error < StandardError;
        end

        class LoggingRedis < Struct.new(:redis)
          @stream = STDOUT
          @disable_color = false
          class << self
            # in case someone might prefer to dump it into STDOUT instead, just set
            # SimpleFeed::Providers::Redis::Driver::LoggingRedis.stream = STDOUT | STDERR | etc...
            attr_accessor :stream, :disable_color
          end

          def method_missing(m, *args, &block)
            if redis.respond_to?(m)
              t1         = Time.now
              result     = redis.send(m, *args, &block)
              delta      = Time.now - t1
              colors     = [:blue, nil, :blue, :blue, :yellow, :cyan, nil, :blue]
              components = [
                Time.now.strftime('%H:%M:%S.%L'), ' rtt=',
                (sprintf '%.5f', delta*1000), ' ms ',
                (sprintf '%15s ', m.to_s.upcase),
                (sprintf '%-40s', args.inspect.gsub(/[",\[\]]/, '')), ' ⇒ ',
                (result.is_a?(::Redis::Future) ? '' : result.to_s)]
              components.each_with_index do |component, index|
                color = self.class.disable_color ? nil : colors[index]
                component = component.send(color) if color
                self.class.stream.printf component
              end
              self.class.stream.puts
              result
            else
              super
            end
          end
        end

        def debug?
          SimpleFeed::Providers::Redis.debug?
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

            if redis.is_a?(::Hash)
              redis_proc = -> { ::Redis.new(**opts[:redis]) }
            elsif redis.is_a?(::Proc)
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

          with_redis { |redis| send_proc.call(redis) }
        end

        class MockRedis
          def method_missing(name, *args, &block)
            puts "calling redis.#{name}(#{args.to_s.gsub(/[\[\]]/, '')}) { #{block ? block.call : nil} }"
          end
        end

        def with_redis
          with_retries do
            pool.with do |redis|
              yield(self.debug? ? LoggingRedis.new(redis) : redis)
            end
          end
        end

        def with_pipelined
          with_retries do
            with_redis do |redis|
              redis.pipelined do
                yield(redis)
              end
            end
          end
        end

        def with_multi
          with_retries do
            with_redis do |redis|
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
