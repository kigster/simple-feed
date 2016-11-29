module SimpleFeed
  module Activity
    class Base
      attr_reader :feed

      def initialize(feed:)
        @feed = feed
      end
    end
  end
end

require_relative 'multi_user'
require_relative 'single_user'
