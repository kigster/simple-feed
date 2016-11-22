require 'redis'
require 'simplefeed/providers/base'
require_relative 'driver'

module SimpleFeed
  module Redis

    # Internal data structure:
    #
    #   ```YAML
    #     u.afkj234.e:
    #       - [ 'John liked Robert', '2016-11-20 23:32:56 -0800' ]
    #       - [ 'Debbie liked Robert', '2016-11-20 23:35:56 -0800' ]
    #     u.afkj234.ct: 2 # total
    #     u.afkj234.cu: 1 # unread
    #     u.afkj234.lr: 016-11-20
    #   ```

    class Provider < ::SimpleFeed::Providers::Base
      include Driver
      #
      # def store(user_id:, value:, at:)
      # end
      #
      # def remove(user_id:, value:, at: nil)
      # end
      #
      # def paginate(user_id:, page:, per_page: feed.per_page)
      # end
      #
      # def all(user_id:)
      # end
      #
      # def reset_last_read(user_id:)
      # end
      #
      # def count(user_id:)
      # end
      #
      # def unread_count(user_id:)
      # end


    end
  end
end
