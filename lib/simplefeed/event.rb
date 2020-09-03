# frozen_string_literal: true

require 'json'

module SimpleFeed
  class Event
    attr_accessor :value, :at
    include Comparable

    class << self
      attr_accessor :is_time
    end

    # This proc can be overridden in a configuration if needed.
    # @example To always assume this is time, set it like so,
    # before defining your feeds.
    #
    #     SimpleFeed::Event.is_time = ->(*) { true }
    #
    self.is_time = ->(float) {
      # assume it's time if epoch is > June 1974 and < December 2040.
      float < 2_237_932_800.0 && float > 139_276_800.0
    }

    def initialize(*args, value: nil, at: Time.now)
      if args && !args.empty?
        self.value = args[0]
        self.at    = args[1]
      end

      self.value ||= value
      self.at    ||= at

      self.at = self.at.to_f

      validate!
    end

    def time
      return nil unless Event.is_time[at]

      Time.at(at)
    rescue ArgumentError
      nil
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

    def hash
      self.value.hash
    end

    def to_json(*_args)
      to_h.to_json
    end

    def to_yaml
      YAML.dump(to_h)
    end

    def to_h
      return @to_h if @to_h

      @to_h ||= { value: value, at: at }
      @to_h.merge!(time: time) if time
      @to_h
    end

    def to_s
      return @to_s if @to_s

      output = StringIO.new
      output.print "<SimpleFeed::Event: "
      output.print(time.nil? ? "[#{at}]" : "[#{time&.strftime(::SimpleFeed::TIME_FORMAT)}]")
      output.print ", [\"#{value}\"]"
      @to_s = output.string
    end

    COLOR_MAP = {
      1 => ->(word) { word.green.bold },
      3 => ->(word) { word.yellow.bold },
    }.freeze

    def to_color_s
      return @to_color_s if @to_color_s

      output = StringIO.new
      to_s.split(/[\[\]]/).each_with_index do |word, index|
        output.print(COLOR_MAP[index]&.call(word) || word.cyan)
      end
      output.print '>'
      @to_color_s = output.string
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
