module SimpleFeed
  module Providers
    class Redis < Provider
      attr_accessor :redis

      def initialize(redis:)
        self.redis = redis
      end

      # def store(user_id:, value:, at:)
      #
      # end
    end
  end
end
