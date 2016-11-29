
require_relative 'providers'
require_relative 'dsl/activities'

module SimpleFeed
  module DSL
    class << self
      attr_accessor :debug

      def debug?
        self.debug
      end

      def for_activity(activity, **opts, &block)
        SimpleFeed::DSL::Activities.new(activity, **opts).instance_eval(&block)
      end
    end
  end

end
