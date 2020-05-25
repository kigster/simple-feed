# frozen_string_literal: true

require_relative 'formatter'
module SimpleFeed
  module DSL
    class Activities
      include SimpleFeed::DSL::Formatter

      attr_accessor :activity, :event_feed, :feed

      def initialize(activity, **opts)
        self.event_feed = activity
        self.feed     = activity.feed
        opts.each_pair do |key, data|
          self.class.instance_eval do
            attr_accessor key
          end
          send("#{key}=".to_sym, data)
        end
      end

      # Creates wrapper methods around the API and optionally prints both calls and return datas
      SimpleFeed::Providers.define_provider_methods(self) do |instance, method, *args, **opts, &block|
        if args&.first
          arg1 = args.shift
          if arg1.is_a?(SimpleFeed::EventTuple)
            event = arg1
          else
            opts[:data] = arg1 unless opts[:data]
            opts[:at]    = args.shift unless opts[:data]
          end
        else
          event = opts.delete(:event)
        end

        opts.merge!(data: event.data, at: event.at) if event

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
        printf "\n#{feed.name.to_s.blue}.#{method.to_s.cyan.bold}#{brackets[0]}#{opts.to_s.gsub(/[{}]/, '').blue}#{brackets[1]} \n" if SimpleFeed::DSL.debug?
        response = yield if block_given?
        puts response.inspect.yellow if SimpleFeed::DSL.debug?
        response
      end
    end
  end
end
