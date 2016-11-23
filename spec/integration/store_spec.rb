require 'spec_helper'

# We'll be generating various times only seconds apart
def at(sec)
  Time.mktime(2016, 12, 01, 10, 00, sec)
end

context 'Integration' do
  context ' ➞ Setup' do
    let(:feed) { SimpleFeed::Fixtures.follow_feed }
    let(:proxy) { feed.provider }
    let(:provider) { proxy.provider }

    context 'FollowFeed' do
      it 'should be correctly defined' do
        expect(feed).to_not be_nil
        expect(feed).to be_kind_of(SimpleFeed::Feed)
        expect(feed.name).to eq :follow_feed
        expect(proxy).to be_kind_of(SimpleFeed::ProviderProxy)
        expect(provider).to be_kind_of(SimpleFeed::MockProvider)
      end

      context 'another feed' do
        let(:another_feed) { SimpleFeed::Fixtures.define_feed(:some_feed) }
        before do
          another_feed.instance_variable_set(:'@name', :follow_feed)
        end
        it 'should be equal to FollowFeed' do
          expect(another_feed).to eql(feed)
        end
      end
    end

    include_examples :event_matrix

    let(:another_id) { 24989800 }

    context 'event list' do
      it 'should be correctly defined' do
        expect(events.size).to eq(3)
        expect(events.last.value).to eq(event_matrix[2][0])
        expect(events.last.at).to eq(event_matrix[2][1])
      end
    end

    let(:user_activity) { feed.user_activity(user_id) }
    let(:another_activity) { feed.user_activity(another_id) }

    context ' ➞ UserActivity#events' do
      let(:manually_sorted_events) { [events[1], events[2], events[0]] }

      context 'event sorting' do
        let(:auto_sorted_events) { SimpleFeed::UserActivity.order_events(events.dup) }
        it 'should be sorted by reverse chronological order' do
          expect(auto_sorted_events).to eq(manually_sorted_events)
        end
      end

      context '#events' do
        before do
          expect(provider).to receive(:all).and_return(events.dup)
        end

        it 'should correctly paginate events' do
          manually_sorted_events.each_with_index do |event, index|
            page = index + 1
            expect(user_activity.events(page: page, per_page: 1)).to eq([event])
          end
          expect(user_activity.events(page: 1, per_page: 2)).to eq [events[1], events[2]]
        end
      end
    end

    context ' ➞ Store Events' do
      before do
        events.each { |e| expect(provider).to receive(:store).with(user_id: user_id, value: e.value, at: e.at) }
      end
      it 'should call provider with :value and :at when supplied :event' do
        events.each { |e| user_activity.store(event: e) }
      end
      it 'should call provider as is without :event' do
        events.each { |e| user_activity.store(value: e.value, at: e.at) }
      end

    end
  end


end
