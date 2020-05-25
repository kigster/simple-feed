# frozen_string_literal: true

require 'base62-rb'
require 'hashie'
require 'set'
require 'objspace'

require 'simplefeed/event'
require_relative 'paginator'
require_relative '../key'
require_relative '../base/provider'

module SimpleFeed
  module Providers
    module Hash
      class Provider < ::SimpleFeed::Providers::Base::Provider
        attr_accessor :h

        include SimpleFeed::Providers::Hash::Paginator

        def self.from_yaml(file)
          new(YAML.parse(File.read(file)))
        end

        def initialize(opts)
          self.h = {}
          h.merge!(opts)
        end

        def store(consumer_ids:, value:, at: Time.now)
          event = create_event(value, at)
          with_response_batched(consumer_ids) do |key|
            add_event(event, key)
          end
        end

        def delete(consumer_ids:, value:, at: nil)
          event = create_event(value, at)
          with_response_batched(consumer_ids) do |key|
            changed_activity_size?(key) do
              __delete(key, event)
            end
          end
        end

        def delete_if(consumer_ids:)
          with_response_batched(consumer_ids) do |key|
            activity(key).map do |event|
              if yield(event, key.consumer)
                __delete(key, event)
                event
              end
            end.compact
          end
        end

        def wipe(consumer_ids:)
          with_response_batched(consumer_ids) do |key|
            deleted = !activity(key).empty?
            wipe_user_record(key)
            deleted
          end
        end

        def paginate(consumer_ids:,
                     page:,
                     per_page: feed.per_page,
                     with_total: false,
                     reset_last_read: false)

          reset_last_read_value(consumer_ids: consumer_ids, at: reset_last_read) if reset_last_read

          with_response_batched(consumer_ids) do |key|
            activity = activity(key)
            result = page && page > 0 ? activity[((page - 1) * per_page)...(page * per_page)] : activity
            with_total ? { events: result, total_count: activity.length } : result
          end
        end

        def fetch(consumer_ids:, since: nil, reset_last_read: false)
          response = with_response_batched(consumer_ids) do |key|
            if since == :unread
              activity(key).reject { |event| event.at < user_meta_record(key).last_read.to_f }
            elsif since
              activity(key).reject { |event| event.at < since.to_f }
            else
              activity(key)
            end
          end
          reset_last_read_value(consumer_ids: consumer_ids, at: reset_last_read) if reset_last_read

          response
        end

        def reset_last_read(consumer_ids:, at: Time.now)
          with_response_batched(consumer_ids) do |key|
            user_meta_record(key)[:last_read] = at
            at
          end
        end

        def total_count(consumer_ids:)
          with_response_batched(consumer_ids) do |key|
            activity(key).size
          end
        end

        def unread_count(consumer_ids:)
          with_response_batched(consumer_ids) do |key|
            activity(key).count { |event| event.at > user_meta_record(key).last_read.to_f }
          end
        end

        def last_read(consumer_ids:)
          with_response_batched(consumer_ids) do |key|
            user_meta_record(key).last_read
          end
        end

        def total_memory_bytes
          ObjectSpace.memsize_of(h)
        end

        def total_users
          h.size / 2
        end

        private

        #===================================================================
        # Methods below operate on a single user only
        #

        def changed_activity_size?(key)
          ua          = activity(key)
          size_before = ua.size
          yield(key, ua)
          size_after = activity(key).size
          (size_before > size_after)
        end

        def create_meta_record
          Hashie::Mash.new(
            { last_read: 0 }
          )
        end

        def create_data_record
          Hashie::Mash.new(
            { activity: SortedSet.new }
          )
        end

        def user_data_record(key)
          h[key.data] ||= create_data_record
        end

        def user_meta_record(key)
          h[key.meta] ||= create_meta_record
        end

        def wipe_user_record(key)
          h[key.data] = create_data_record
        end

        def activity(key, event = nil)
          user_data_record(key)[:activity] << event if event
          user_data_record(key)[:activity].to_a
        end

        def add_event(event, key)
          uas = user_data_record(key)[:activity]
          if uas.include?(event)
            false
          else
            uas << event.dup
            if uas.size > feed.max_size
              uas.delete(uas.to_a.last)
            end
            true
          end
        end

        def __last_read(key, _value = nil)
          user_meta_record(key)[:last_read]
        end

        def __delete(key, event)
          user_data_record(key)[:activity].delete(event)
        end

        def create_event(*args, **opts)
          ::SimpleFeed::Event.new(*args, **opts)
        end
      end
    end
  end
end
