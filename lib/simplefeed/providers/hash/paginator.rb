# frozen_string_literal: true

module SimpleFeed
  module Providers
    module Hash
      # Include this module into any provider etc that has access to the +feed.fetch+
      # methods, and it will provide +paginate+ method based on all.
      #
      # Of course this is not very efficient, because it requires fetching all events for the user.
      module Paginator
        def paginate(consumers:, page: nil, per_page: feed.per_page, &block)
          response = feed.fetch(consumers: consumers)
          response = SimpleFeed::Consumer::Response.new(response.to_h)
          response.transform do |*, events|
            paginate_items(order_events(events, &block), page: page, per_page: per_page)
          end
        end

        def paginate_items(items, page: nil, per_page: nil)
          page && page > 0 ? items[((page - 1) * per_page)...(page * per_page)] : items
        end

        def order_events(events, &block)
          return nil unless events

          events.sort do |a, b|
            block ? yield(a, b) : b.at <=> a.at
          end
        end
      end
    end
  end
end
