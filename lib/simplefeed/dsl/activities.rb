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
        event = opts.delete(:event)
        opts.merge!(value: event.value, at: event.at) if event

        printf " #{instance.feed.name.to_s.blue}.#{sprintf("%-16s", method.to_s).magenta}(#{opts.to_s.gsub(/[{}]/, '').blue}) \n\t\t\t" if SimpleFeed::DSL.debug?
        response = instance.ua.send(method, *args, **opts)

        puts '———> ' + response.inspect.green if SimpleFeed::DSL.debug?
        block.call(response) if block
        response
      end

      def counts
        return ua.total_count, ua.unread_count
      end

    end
  end
end
