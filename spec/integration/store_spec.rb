require 'spec_helper'

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
        expect(events.last.value).to eq(EVENT_MATRIX[2][0])
        expect(events.last.at).to eq(EVENT_MATRIX[2][1])
      end
    end

    let(:user_ids) { [user_id, another_id] }
    let(:user_activity) { feed.user_activity(user_ids) }

    context ' ➞ Store Events' do
      before do
        events.each { |e| expect(provider).to receive(:store).with(user_ids: user_ids, value: e.value, at: e.at) }
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
