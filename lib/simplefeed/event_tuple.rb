# frozen_string_literal: true

require 'json'

module SimpleFeed
  class EventTuple
    class << self
      def event(data, at = nil)
        new(data: data, at: at)
      end
    end

    attr_reader :data, :at

    include Comparable

    # @example Creating an event
    #
    #     @event_tuple = SimpleFeed::EventTuple.event(data, timestamp)
    #     @event_tuple = SimpleFeed::EventTuple.new(data: data, at: timestamp)
    #
    def initialize(*args, data: nil, value: nil, time: nil, at: nil, score: nil)
      @data, @at = *args if args&.size == 2
      @data ||= (data || value)
      @at ||= (time || at || score || Time.now)&.to_f

      raise ArgumentError, "Can't determine EventType.at from the arguments" unless @at
      raise ArgumentError, "Can't determine EventType.data from the arguments" unless @data
    end

    def time
      Time.at(at)
    end

    def <=>(other)
      -at <=> -other.at
    end

    def eql?(other)
      self == other
    end

    def ==(other)
      other.is_a?(SimpleFeed::EventTuple) &&
        data == other.data
    end

    def to_h
      { data: data, at: at, time: time }
    end

    def hash
      data.hash
    end

    def to_json(*_args)
      to_h.to_json
    end

    def to_yaml
      YAML.dump(to_h)
    end

    def to_s
      "<SimpleFeed::EventTuple: data='#{data}', at='#{at}', time='#{time}'>"
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
  end
end
