require 'spec_helper'

require 'simplefeed/providers/hash/paginator'

RSpec.describe SimpleFeed::Providers::Hash::Paginator do

  class TestClass < SimpleFeed::Providers::Base::Provider
    include SimpleFeed::Providers::Hash::Paginator

    def initialize(feed)
      self.feed = feed
    end
  end

  let(:feed) { SimpleFeed::Fixtures.follow_feed }

  context '#events' do
    include_examples :event_matrix

    let(:manually_sorted_events) { [events[1], events[2], events[0]] }

    context 'event sorting' do
      let(:auto_sorted_events) { TestClass.new(feed).order_events(events.dup) }
      it 'should be sorted by reverse chronological order' do
        expect(auto_sorted_events).to eq(manually_sorted_events)
      end
    end

    context '#events' do
      let(:user_id) { 23409239048293 }
      let(:paginated) { TestClass.new(feed) }
      let(:generated_response) { SimpleFeed::Response.new({ user_id => events.map(&:dup).dup }) }

      before do
        expect(feed).to receive(:fetch).
          exactly(4).times.
          and_return(generated_response)
      end

      it 'should correctly paginate events' do
        manually_sorted_events.each_with_index do |event, index|
          page = index + 1
          response = paginated.paginate(user_ids: [user_id], page: page, per_page: 1)
          expect(response[user_id]).to eq([event])
        end
        expect(paginated.paginate(user_ids: [user_id], page: 1, per_page: 2)[user_id]).to eq [events[1], events[2]]
      end
    end
  end
end
