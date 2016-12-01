module SimpleFeed
  module DSL
    class Activities
      attr_accessor :ua, :feed

      def initialize(ua, **opts)
        self.ua   = ua
        self.feed = ua.feed
        opts.each_pair do |key, value|
          self.class.instance_eval do
            attr_accessor key
          end
          self.send("#{key}=".to_sym, value)
        end
      end

      def execute(&block)
        instance_eval(&block)
      end

      # Creates wrapper methods around the API and optionally prints both calls and return values
      #
      # def store(event: .., | value:, at: )
      #   ua.store(**opts)
      # end
      # etc...
      SimpleFeed::Providers.define_provider_methods(self) do |instance, method, *args, **opts, &block|
        if args&.first
          event = args.shift
          if !event.is_a?(SimpleFeed::Event) && args.size == 1
            event = SimpleFeed::Event(value: event, at: args[1] || Time.now)
          end
        else
          event = opts.delete(:event)
        end

        opts.merge!(value: event.value, at: event.at) if event
        brackets = opts.empty? ? ['', ''] : %w{( )}

        printf "\n#{instance.feed.name.to_s.blue}.#{method.to_s.cyan.bold}#{brackets[0]}#{opts.to_s.gsub(/[{}]/, '').blue}#{brackets[1]} \n" if SimpleFeed::DSL.debug?

        response = instance.ua.send(method, *args, **opts)

        puts response.inspect.yellow if SimpleFeed::DSL.debug?

        if block
          if instance.context
            instance.context.instance_exec(response, &block)
          else
            block.call(response)
          end
        end

        response
      end

    end
  end
end
