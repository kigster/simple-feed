require 'base62-rb'
require 'hashie'
require 'set'

require 'simplefeed/event'
require_relative 'paginator'
require_relative '../serialization/key'
require_relative '../base/provider'

module SimpleFeed
  module Providers
    module Hash
      class Provider < ::SimpleFeed::Providers::Base::Provider
        attr_accessor :h

        include SimpleFeed::Providers::Hash::Paginator

        def self.from_yaml(file)
          self.new(YAML.load(File.read(file)))
        end

        def initialize(**opts)
          self.h = {}
          h.merge!(opts)
        end

        #——————————————————————————————————————————————————————————————
        # Public API
        #——————————————————————————————————————————————————————————————
        # TODO: single user delegator
        # def store_1u(user_id, **opts)
        #   push event(user_id: user_id, **opts)
        # end #

        # @param [Array] user_ids array of user IDs for the operation
        # @param [Hash] opts the options for the method
        # @option opts [String] :value data to store in the backend
        # @option opts [Time] :at time stamp when the story was created
        #
        # @return: Response.new( { user_id: true | false (added or not)
        def store(user_ids:, **opts)
          with_response_batched(user_ids) do |key, response|
            push(event(user_id: key, **opts))
          end
        end

        def remove(user_ids:, **opts)
          with_response_batched(user_ids) do |key, response|
            pop(event(user_id: "#{key}", **opts))
          end
        end

        def wipe(user_ids:)
          with_response_batched(user_ids) do |key, response|
            activity(key.to_s, true)
            true
          end
        end

        def all(user_ids:)
          with_response_batched(user_ids) do |key, response|
            activities(key)
          end
        end

        def paginate(user_ids:, page:, per_page: feed.per_page, **options)
          reset_last_read(user_ids: user_ids) unless options[:peek]
          with_response_batched(user_ids) do |key, response|
            activities = activities(key)
            (page && page > 0) ? activities[((page - 1) * per_page)...(page * per_page)] : activities
          end
        end

        def reset_last_read(user_ids:, at: Time.now)
          with_response_batched(user_ids) do |key, response|
            user_record(key)[:last_read]    = at
            user_record(key)[:unread_count] = 0
            at
          end
        end

        def total_count(user_ids:)
          fetch_meta(:total_count, user_ids)
        end

        def unread_count(user_ids:)
          fetch_meta(:unread_count, user_ids)
        end

        def last_read(user_ids:)
          fetch_meta(:last_read, user_ids)
        end

        private

        def fetch_meta(name, user_ids)
          name = name.to_sym unless name.is_a?(Symbol)
          with_response_batched(user_ids) do |key, response|
            user_record(key)[name]
          end
        end

        #===================================================================
        # Methods below operate on a single user only
        #

        def user_record(key, wipe = false)
          h[key.to_s] = nil if wipe
          h[key.to_s] ||= Hashie::Mash.new(
            { total_count:  0,
              unread_count: 0,
              last_read:    nil,
              activity:     SortedSet.new }
          )
        end

        def activities(key)
          activity(key).map { |ea| ea.deserialize(key.user_id) }
        end

        def activity(key, *args)
          user_record(key, *args)[:activity]
        end

        def increment_counts(user_id, by = 1)
          %i(total_count unread_count).each do |field|
            if (user_record(user_id)[field] += by) < 0
              user_record(user_id)[field] = 0
            end
          end
        end

        def push(event)
          user_activity    = activity(event.user_id)
          event_serialized = event.serialize
          if user_activity.include?(event_serialized)
            false
          else
            user_activity << event_serialized
            increment_counts(event.user_id)
            true
          end
        end

        def pop(event)
          event_serialized = event.serialize
          user_activity    = activity(event.user_id)
          if user_activity.include?(event_serialized)
            user_activity.delete(event_serialized)
            increment_counts(event.user_id, -1)
            true
          else
            false
          end
        end

        def event(**opts)
          ::SimpleFeed::Event.new(opts)
        end

      end
    end
  end
end
