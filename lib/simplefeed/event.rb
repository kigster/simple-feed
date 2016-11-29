require 'json'

module SimpleFeed

  class Event
    attr_accessor :user_id, :value, :at

    def initialize(*args, value: nil, at: nil, user_id: nil)
      if args && args.size == 2
        self.value = args[0]
        self.at    = args[1]
      else
        self.value   = value
        self.at      = at
        self.user_id = user_id
      end
      self.at = self.at.to_f if self.at.is_a?(Time)
      raise ArgumentError, 'either pass arguments as hash: { value: <value>, at: <value> } or array: [ value, at ],' +
        "Got #{self.inspect.blue}, args=#{args}" unless self.value && self.at
    end

    def self.deserialize(user_id, hash)
      self.class.new(user_id: user_id, value: hash[:value], at: Time.at(hash[:at] / 1000))
    end

    def serialize
      { value: value, at: (1000.0 * at.to_f).to_i }
    end

    def <=>(other)
      self.at <=> other.at
    end

    def eql?(other)
      self == other
    end

    def ==(other)
      other.is_a?(SimpleFeed::Event) &&
        self.user_id == other.user_id &&
        self.value == other.value &&
        sprintf('%.3f', self.at) == sprintf('%.3f', other.at)
    end

    def to_h
      { value: value, at: at}
    end

    def to_json
      h = self.to_h
      h.merge!({ user_id: user_id }) if user_id
      h.to_json
    end

    def inspect
      "#<#{self.class.name}##{object_id} #{to_json}>"
    end

    private

    def copy(&block)
      copy = self.clone
      copy.instance_eval(&block)
      copy
    end

  end
end
