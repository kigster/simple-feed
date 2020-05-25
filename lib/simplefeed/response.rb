# frozen_string_literal: true

require 'hashie'
require 'forwardable'
require 'simplefeed'

module SimpleFeed
  class Response
    extend Forwardable

    def_delegators :@result, :delete, :key?, :value?, :values, :keys, :size, :merge!

    include Enumerable

    def each
      if block_given?
        @result.each_pair do |consumer_id, result|
          yield(consumer_id, result)
        end
      else
        @result.keys.to_enum
      end
    end

    def initialize(data = {})
      @result = data.dup
    end

    def for(key_or_consumer_id, result = nil)
      consumer_id = key_or_consumer_id.is_a?(SimpleFeed::Providers::Key) ?
        key_or_consumer_id.consumer :
        key_or_consumer_id

      @result[consumer_id] = result || yield(@result[consumer_id])
    end

    def consumer_ids
      @result.keys
    end

    def has_user?(consumer_id)
      @result.key?(consumer_id)
    end

    def user_count
      @result.size
    end

    def to_h
      @result.to_h
    end

    # Passes results assigned to each user to a transformation
    # function that in turn must return a transformed value for
    # an individual response, and be implemented in the subclasses
    def transform
      if block_given?
        @result.each_pair do |consumer_id, value|
          @result[consumer_id] = yield(consumer_id, value)
        end
      end
      self
    end

    def result(consumer_id = nil)
      if consumer_id
        @result[consumer_id]
      else
        if @result.values.size == 1
          @result.values.first
        else
          @result.to_hash
        end
      end
    end

    alias_method :[], :result
  end
end
