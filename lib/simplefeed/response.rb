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
        @result.each_pair do |user_id, result|
          yield(user_id, result)
        end
      else
        @result.keys.to_enum
      end
    end

    def initialize(data = {})
      @result = data.dup
    end

    def for(key_or_user_id, result = nil)
      user_id = key_or_user_id.is_a?(SimpleFeed::Providers::Key) ?
        key_or_user_id.user_id :
        key_or_user_id

      @result[user_id] = result ? result : yield(@result[user_id])
    end

    def user_ids
      @result.keys
    end

    def has_user?(user_id)
      @result.key?(user_id)
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
        @result.each_pair do |user_id, value|
          @result[user_id] = yield(user_id, value)
        end
      end
      self
    end

    def result(user_id = nil)
      if user_id then
        @result[user_id]
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
