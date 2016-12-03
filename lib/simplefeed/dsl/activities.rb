require_relative 'formatter'
module SimpleFeed
  module DSL
    class Activities

      include SimpleFeed::DSL::Formatter

      attr_accessor :activity, :feed

      def initialize(activity, **opts)
        self.activity = activity
        self.feed     = activity.feed
        opts.each_pair do |key, value|
          self.class.instance_eval do
            attr_accessor key
          end
          self.send("#{key}=".to_sym, value)
        end
      end

      # Creates wrapper methods around the API and optionally prints both calls and return values
      #
      # def store(event: .., | value:, at: )
      #   activity.store(**opts)
      # end
      # etc...
      SimpleFeed::Providers.define_provider_methods(self) do |instance, method, *args, **opts, &block|
        if args&.first
          arg1 = args.shift
          if arg1.is_a?(SimpleFeed::Event)
            event = arg1
          else
            opts[:value] = arg1 unless opts[:value]
            opts[:at]    = args.shift unless opts[:value]
          end
        else
          event = opts.delete(:event)
        end

        opts.merge!(value: event.value, at: event.at) if event

        response = instance.instance_eval do
          print_debug_info(method, **opts) do
            activity.send(method, *args, **opts)
          end
        end

        if block
          if instance.context
            instance.context.instance_exec(response, &block)
          else
            block.call(response)
          end
        end

        response
      end

      private

      def print_debug_info(method, **opts)
        brackets = opts.empty? ? ['', ''] : %w{( )}
        printf "\n#{self.feed.name.to_s.blue}.#{method.to_s.cyan.bold}#{brackets[0]}#{opts.to_s.gsub(/[{}]/, '').blue}#{brackets[1]} \n" if SimpleFeed::DSL.debug?
        response = yield if block_given?
        puts response.inspect.yellow if SimpleFeed::DSL.debug?
        response
      end
    end
  end
end
