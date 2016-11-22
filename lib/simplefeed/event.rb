module SimpleFeed
  class Event
    attr_reader :user_id,
                :value,
                :at

    def initialize(user_id:, value:, at:)
      @user_id = user_id
      @value   = value
      @at      = at
    end
  end
end
