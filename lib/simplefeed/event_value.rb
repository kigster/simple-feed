require_relative 'event'

module SimpleFeed
  class EventValue < Struct.new(:value, :at)
    def deserialize(user_id)
      Event.new(user_id: user_id, value: value, at: at)
    end

    def <=>(other)
      self.at <=> other.at
    end
  end
end
