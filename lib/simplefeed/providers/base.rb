module SimpleFeed
  module Providers
    class Base
      attr_accessor :feed


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
