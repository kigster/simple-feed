module SimpleFeed
  module Providers
    # Include this module into any provider etc that has access to the +feed.all+
    # methods, and it will provide +paginate+ method based on all.
    #
    # Of course this is not very efficient, because it requires fetching all events for the user.
    module Paginator

      def paginate(user_ids:, page: nil, per_page: feed.per_page, &block)
        all_events = feed.all(user_ids: user_ids)
        order_events(all_events, &block)
        (page && page > 0) ? all_events[((page - 1) * per_page)...(page * per_page)] : all_events
      end

      def order_events(events, &block)
        return nil unless events
        events.sort! do |a, b|
          block ? yield(a, b) : b.at <=> a.at
        end
      end
    end
  end
end
