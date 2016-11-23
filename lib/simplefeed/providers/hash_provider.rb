require 'base62-rb'
require 'hashie'
require 'simplefeed/event'

module SimpleFeed
  module Providers
    class HashProvider < Base
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
        user_activity(user_id, true)
      end

      def all(user_id:)
        user_activity(user_id).map { |ea| ea.deserialize(user_id) }
      end

      def paginate(user_id:, page:, per_page: feed.per_page, **options)
        reset_last_read(user_id) unless options[:peek]

        __all = all(user_id: user_id)
        (page && page > 0) ? __all[((page - 1) * per_page)...(page * per_page)] : __all
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
            activity:     [] }
        )
      end

      def increment_count(user_id, by = 1)
        %i(total_count unread_count).each do |field|
          if (user_record(user_id)[field] += by) < 0
            user_record(user_id)[field] = 0
          end
        end
      end

      def user_activity(user_id, *args)
        user_record(user_id, *args)[:activity]
      end

      def push(ev)
        ua = user_activity(ev.user_id)
        ua << ev.serialize
        increment_count(ev.user_id)
        ua.sort!
        ev
      end

      def pop(ev)
        evs = ev.serialize
        user_activity(ev.user_id).reject! do |existing|
          existing.eql?(evs)
        end
        increment_count(ev.user_id, -1)
      end

      def event(**opts)
        ::SimpleFeed::Event.new(opts)
      end

    end
  end
end
