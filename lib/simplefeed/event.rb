require_relative 'event_value'

module SimpleFeed
  class Event < EventValue
    attr_accessor :user_id

    def initialize(user_id:, value:, at:)
      self.user_id = user_id
      super(value, at)
    end

    def eql?(other)
      super(other) && self.user_id == other.user_id
    end

    def serialize
      EventValue.new(value: value, at: at)
    end
  end
end
