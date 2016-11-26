require 'hashie'

module SimpleFeed
  class Response
    attr_accessor :user_ids, :operation

    def initialize(operation)
      self.user_ids = []
      self.operation = operation
      @result = {}
    end

    def for(user_id, result = nil)
      @result[user_id] = result ? result : yield
    end

    def map
      new_result = {}
      @result.each_pair do |key, value|
        new_result[key] = yield(key, value)
      end
      @result = new_result
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
