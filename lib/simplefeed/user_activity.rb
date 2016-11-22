module SimpleFeed
  class UserActivity
    attr_reader :user_id, :events, :last_read_at

    def initialize(user_id:,
                   events: [],
                   last_read_at: nil,
                   unread_count: 0,
                   total_count: 0)

      @user_id      = user_id
      @events       = events
      @last_read_at = last_read_at
      @unread_count = unread_count
      @total_count  = total_count
    end
  end

end
