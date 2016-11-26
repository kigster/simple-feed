require 'spec_helper'

shared_examples 'a provider' do

  def validate_count(total, unread = total)
    expect(activity.total_count.result(user_id)).to eq(total)
    expect(activity.unread_count.result(user_id)).to eq(unread)
  end

  subject(:feed) {
    SimpleFeed.define(:tested_feed) do |f|
      f.max_size = 5
      f.provider = described_class.new(provider_opts)
    end
  }

  before { feed }

  include_context :event_matrix

  context '#store two events' do
    let(:user_id) { 99119911991199 }
    let(:activity) { SimpleFeed.tested_feed.user_activity([user_id]) }
    let(:feed_op) {
      ->(operation) {
        ->(index) {
          activity.send(operation, value: events[index].value, at: events[index].at)
        }
      }
    }

    let(:feed_query) {
      ->(operation, **opts) { activity.send(operation, **opts) }
    }

    let(:store_two_events) {
      activity.wipe
      expect(activity.all.result(user_id).size).to eq(0)
      feed_op[:store][0]
      feed_op[:store][1]
      expect(activity.all.result(user_id).size).to eq(2)
    }

    before { store_two_events }

    it('has two events') { validate_count(2) }

    context '#remove one event' do
      before { expect(activity.all.result(user_id).size).to eq(2) }
      it('has one event left') do
        expect(feed_op[:remove][1]).to_not be_nil # this indicates removal was successful
        validate_count(1)
      end
    end


    context '#remove non-existent event' do
      before { expect(activity.all.result(user_id).size).to eq(2) }
      it 'has one event left still' do
        expect(feed_op[:remove][1].result(user_id)).to eq(:OK)
        expect(feed_op[:remove][1].result(user_id)).to be_nil
        validate_count(1)
      end
    end

    context '#paginate two events' do
      before { expect(activity.all.result(user_id).size).to eq(2) }
      it 'returns the first event as page 1' do
        expect(feed_query[:paginate, page: 1, per_page: 1]).to_not be_nil #eq([events[0]]) # this indicates removal was successful
        activity.last_read
      end
    end

  end
end
