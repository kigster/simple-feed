module SimpleFeed
  module Providers
    class BaseProvider
      attr_accessor :feed

      protected

      def key(user_id)
        Key.new(user_id, feed.namespace)
      end

      def time_to_score(at)
        (1000 * at.to_f).to_i
      end

      def to_array(user_ids)
        user_ids.is_a?(Array) ? user_ids : [user_ids]
      end

      def batch_size
        feed.meta[:batch_size] || 100
      end

      def with_response_batched(operation, user_ids)
        with_response(operation) do |response|
          batch(user_ids) do |key|
            yield(response, key)
          end
        end
      end

      def with_response(operation)
        response = SimpleFeed::Response.new(operation)
        yield(response)
        if self.respond_to?(:map_response)
          response.map do |*, result|
            self.send(:map_response, result)
          end
        end
        response
      end

      def batch(user_ids)
        to_array(user_ids).each_slice(batch_size) do |batch|
          batch.each do |user_id|
            yield(key(user_id))
          end
        end
      end

      # def retry_block(times, &block)
      #   count = 0
      #   begin
      #     block.call
      #   rescue
      #     if count < times
      #       count += 1
      #       retry
      #     else
      #       raise
      #     end
      #   end
      #   return { retries: count }
      # end

    end
  end
end
