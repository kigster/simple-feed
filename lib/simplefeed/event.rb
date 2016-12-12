require 'json'

module SimpleFeed
  class Event
    attr_accessor :value, :at
    include Comparable

    def initialize(*args, value: nil, at: Time.now)
      if args && args.size > 0
        self.value = args[0]
        self.at    = args[1]
      end

      self.value ||= value
      self.at    ||= at

      self.at = self.at.to_f

      validate!
    end

    def time
      Time.at(at)
    end

    def <=>(other)
      -self.at <=> -other.at
    end

    def eql?(other)
      self == other
    end

    def ==(other)
      other.is_a?(SimpleFeed::Event) &&
        self.value == other.value
    end

    def to_h
      { value: value, at: at, time: time }
    end

    def hash
      self.value.hash
    end

    def to_json
      to_h.to_json
    end

    def to_yaml
      YAML.dump(to_h)
    end

    def to_s
      "<SimpleFeed::Event: value='#{value}', at='#{at}', time='#{time}'>"
    end

    def to_color_s
      counter = 0
      to_s.split(/[']/).map do |word|
        counter += 1
        counter.even? ? word.yellow.bold : word.blue
      end.join('')
    end

    def inspect
      super
    end

    private

    def validate!
      unless self.value && self.at
        raise ArgumentError, "Required arguments missing, value=[#{value}], at=[#{at}]"
      end
    end

  end
end
