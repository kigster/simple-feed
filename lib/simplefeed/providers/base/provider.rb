# frozen_string_literal: true

require 'simplefeed/key'
require 'simplefeed/publisher/response'
require 'simplefeed/consumer/response'
require 'date'
require 'time'

module SimpleFeed
  module Providers
    class NotImplementedError < ::StandardError
      def initialize(klass, method)
        super("Class #{klass.name} did not implement abstract method #{method}, but was called.")
      end
    end

    module Base
      class Provider
        attr_accessor :feed

        class << self
          def class_to_registry(klass)
            klass.name.split('::').delete_if { |n| %w(SimpleFeed Providers Provider).include?(n) }.compact.last.downcase.to_sym
          end

          def inherited(klass)
            SimpleFeed::Providers.register(class_to_registry(klass), klass)
          end
        end

        def store(**opts)
          publish(**opts)
        end

        protected

        def reset_last_read_data(consumers:, at: nil)
          at = [Time, DateTime, Date].include?(at.class) ? at : Time.now
          at = at.to_time if at.respond_to?(:to_time)
          at = at.to_f if at.respond_to?(:to_f)

          if respond_to?(:reset_last_read)
            reset_last_read(consumers: consumers, at: at)
          else
            raise ArgumentError, "Class #{self.class} does not implement #reset_last_read method"
          end
        end

        def tap(data)
          yield
          data
        end

        def key(consumer_id)
          feed.key(consumer_id)
        end

        def to_array(consumers)
          consumers.is_a?(Array) ? consumers : [consumers]
        end

        def batch_size
          feed.batch_size
        end

        def with_response_batched(consumers, external_response = nil)
          with_response(external_response) do |response|
            batch(consumers) do |key|
              response.for(key.consumer_id) { yield(key, response) }
            end
          end
        end

        def batch(consumers)
          to_array(consumers).each_slice(batch_size) do |batch|
            batch.each do |consumer_id|
              yield(key(consumer_id))
            end
          end
        end

        def with_response(response = nil)
          response ||= SimpleFeed::Publisher::Response.new
          yield(response)
          if respond_to?(:transform_response)
            response.transform do |consumer_id, result|
              # calling into a subclass
              transform_response(consumer_id, result)
            end
          end
          response
        end
      end
    end
  end
end
