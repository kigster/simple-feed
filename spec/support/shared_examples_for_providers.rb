require 'spec_helper'

# Requires the following variables set:
#  * provider_opts

shared_examples 'a provider' do

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
    let(:user_ids) { [user_id] }
    let(:activity) { SimpleFeed.tested_feed.user_activity(user_ids) }

    def validate_count(user_id, total, unread = total)
      expect(op_feed(:total_count, user_id)[user_id]).to eq(total)
      expect(op_feed(:unread_count, user_id)[user_id].to_i).to eq(unread)
    end

    def op_event(operation, user_ids, event)
      op_feed(operation, user_ids, value: event.value, at: event.at)
    end

    def op_feed(operation, user_ids, **opts)
      opts.empty? ? activity.send(operation, user_ids: user_ids) : activity.send(operation, user_ids: user_ids, **opts)
    end

    def store_two_events(user_id)
      activity.wipe
      expect(op_feed(:all, user_ids)[user_id].size).to eq(0)
      op_event(:store, user_id, events[0]).inspect
      op_event(:store, user_id, events[1]).inspect
      expect(op_feed(:all, user_ids)[user_id].size).to eq(2)
    end 

    before { store_two_events(user_id) }

    it('has two events') { validate_count(user_id, 2, 2) }

    context '#remove' do
      before { store_two_events(user_id) }
      context 'one event' do
        it('has one event left') do
          expect(op_event(:remove, user_id, events[1])[user_id]).to_not be_nil
          validate_count(user_id, 1, 1)
        end
      end

      context 'non-existing event' do
        it 'has one event left still' do
          expect(op_feed(:all, user_id)[user_id].size).to eq(2)
          expect(op_event(:remove, user_id, events[1])[user_id]).to eq(1)
          expect(op_event(:remove, user_id, events[1])[user_id]).to be_nil
          validate_count(user_id, 1, 1)
        end
      end
    end

    context '#paginate' do
      let(:ts) { Time.now }
      it 'resets last read, and returns the first event as page 1' do
        expect(op_feed(:reset_last_read, user_id, at: ts)[user_id]).to eq(ts)
        expect(op_feed(:paginate, user_id, page: 1, per_page: 1)[user_id]).to_not be_empty
        expect(op_feed(:last_read, user_id)[user_id]).not_to eq(ts)
      end
    end

  end
end
