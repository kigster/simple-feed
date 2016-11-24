require 'base62-rb'
require 'hashie'
require 'simplefeed/event'
require 'set'

module SimpleFeed
  module Providers
    class HashProvider < BaseProvider
      attr_accessor :h

      def self.from_yaml(file)
        self.new(YAML.load(File.read(file)))
      end

      def initialize(**opts)
        self.h = {}
        h.merge!(opts)
      end

      def store(**opts)
        push event(opts)
      end

      def remove(**opts)
        pop event(opts)
      end

      def wipe(user_id:)
        activity(user_id, true)
      end

      def all(user_id:)
        activity(user_id).map { |ea| ea.deserialize(user_id) }
      end

      def paginate(user_id:, page:, per_page: feed.per_page, **options)
        reset_last_read(user_id: user_id) unless options[:peek]

        activities  = all(user_id: user_id)
        (page && page > 0) ? activities[((page - 1) * per_page)...(page * per_page)] : activities
      end

      def reset_last_read(user_id:, at: Time.now)
        user_record(user_id).last_read    = at
        user_record(user_id).unread_count = 0
      end

      def total_count(user_id:)
        user_record(user_id).total_count
      end

      def unread_count(user_id:)
        user_record(user_id).unread_count
      end

      def last_read(user_id:)
        user_record(user_id).last_read
      end

      def recalculate!
        raise ArgumentError, 'Not implemented yet'
      end

      private

=begin
      Sets up the user record in the hash and initializes it if needed.
=end
      def user_record(user_id, wipe = false)
        h[Base62.encode(user_id)] = nil if wipe
        h[Base62.encode(user_id)] ||= Hashie::Mash.new(
          { total_count:        0,
            unread_count: 0,
            last_read:    nil,
            activity:     SortedSet.new }
        )
      end

      def activity(user_id, *args)
        user_record(user_id, *args)[:activity]
      end

      def increment_counts(user_id, by = 1)
        %i(total_count unread_count).each do |field|
          if (user_record(user_id)[field] += by) < 0
            user_record(user_id)[field] = 0
          end
        end
      end

      def push(ev)
        ua = activity(ev.user_id)
        evs = ev.serialize
        if ua.include?(evs)
          nil
        else
          ua << evs
          increment_counts(ev.user_id)
          ua
        end
      end

      def pop(ev)
        evs = ev.serialize
        ua = activity(ev.user_id)
        if ua.include?(evs)
          ua.delete(evs)
          increment_counts(ev.user_id, -1)
          ua
        else
          nil
        end
      end

      def event(**opts)
        ::SimpleFeed::Event.new(opts)
      end

    end
  end
end
