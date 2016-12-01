require 'json'

module SimpleFeed

  class Event
    attr_accessor :value, :at

    def initialize(*args, value: nil, at: Time.now)
      if args && args.size > 0
        self.value = args[0]
        self.at    = args[1] || Time.now
      else
        self.value = value
        self.at    = at
      end

      self.at = self.at.to_f unless self.at.is_a?(Float)

      raise ArgumentError, 'either pass arguments as hash: { value:, at: <Time.now> } or args array: [ value, at = Time.now ],' +
        "Got #{self.inspect.blue}, args=#{args}" unless self.value && self.at
    end

    def <=>(other)
      self.at <=> other.at
    end

    def eql?(other)
      self == other
    end

    def ==(other)
      other.is_a?(SimpleFeed::Event) &&
        self.value == other.value
    end

    def to_h
      { value: value, at: at }
    end

    def hash
      self.value.hash
    end

    def to_json
      to_h.to_json
    end

    def inspect
      "#<#{self.class.name}##{object_id} #{to_json}>"
    end

    def to_s
      inspect
    end

    private

    def copy(&block)
      copy = self.clone
      copy.instance_eval(&block)
      copy
    end

  end
end
