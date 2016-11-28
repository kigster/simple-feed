
module SimpleFeed

  class Event
    attr_accessor :user_id, :value, :at

    def initialize(*args, value: nil, at: nil, user_id: nil)
      if args && args.size == 2
        self.value   = args[0]
        self.at      = args[1]
      else
        self.value   = value
        self.at      = at
        self.user_id = user_id
      end
      raise ArgumentError, 'either pass arguments as hash: { value: <value>, at: <value> } or array: [ value, at ]' unless self.value && self.at
    end

    def deserialize(user_id)
      copy { self.user_id = user_id }
    end

    def serialize
      copy { self.user_id = nil }
    end

    def <=>(other)
      self.at <=> other.at
    end

    def eql?(other)
      other.is_a?(SimpleFeed::Event) &&
        self.user_id == other.user_id &&
        self.value == other.value &&
        self.at == other.at
    end

    private

    def copy(&block)
      copy = self.clone
      copy.instance_eval(&block)
      copy
    end


  end
end
