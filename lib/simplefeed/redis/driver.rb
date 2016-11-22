require 'redis'
require 'redis/connection/hiredis'

module SimpleFeed
  module Redis
    module Driver
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
            self.pool = ConnectionPool.new(size: opts[:pool_size] || 2, &redis_proc)
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
        send_proc ||= ->(redis) { redis.send(redis_method, *args, &block) }
        # puts "self.exec #{redis_method} #{args.join(' ')}" if ENV['DEBUG']

        if opts[:pipelined]
          opts.delete :pipelined
          with_pipelined { |redis| send_proc.call(redis) }
        else
          with { |redis| send_proc.call(redis) }
        end
      rescue StandardError => e
        log(e) if self.respond_to?(:log)
        on_error(e)
      end

      def with_pipelined
        with do |redis|
          redis.pipelined do
            yield(redis)
          end
        end
      end

      def with
        tries ||= 3
        pool.with do |redis|
          yield(redis)
        end
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
