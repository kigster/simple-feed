require 'spec_helper'
require 'simplefeed/providers/paginator'

RSpec.describe SimpleFeed::Providers::Paginator do

  class TestClass < SimpleFeed::Providers::BaseProvider
    include SimpleFeed::Providers::Paginator
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
      let(:user_ids) { 23409239048293 }
      let(:paginated) { TestClass.new(feed) }

      before do
        expect(feed).to receive(:all).exactly(4).times.and_return(events.dup)
      end

      it 'should correctly paginate events' do
        manually_sorted_events.each_with_index do |event, index|
          page = index + 1
          expect(paginated.paginate(user_ids: user_ids, page: page, per_page: 1)).to eq([event])
        end
        expect(paginated.paginate(user_ids: user_ids, page: 1, per_page: 2)).to eq [events[1], events[2]]
      end
    end
  end
end
