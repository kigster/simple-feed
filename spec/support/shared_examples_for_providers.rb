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

  def op_feed(operation, user_id, **opts)
    opts.empty? ?
      SimpleFeed.tested_feed.send(operation, user_ids: user_id) :
      SimpleFeed.tested_feed.send(operation, user_ids: user_id, **opts)
  end

  def op_event(operation, user_id, event)
    op_feed(operation, user_id, value: event.value, at: event.at)
  end

  def op_fetch(operation, user_id)
    op_feed(operation, user_id)[user_id]
  end

  def check_counts(user_id, total, unread = total)
    expect(total(user_id)[user_id]).to eq(total)
    expect(unread(user_id)[user_id]).to eq(unread)
  end

  def all(user_id)
    result = op_feed(:all, user_id)
    yield(result) if block_given?
    result
  end

  def total(user_id)
    result = op_feed(:total_count, user_id)
    yield(result) if block_given?
    result
  end

  def unread(user_id)
    result = op_feed(:unread_count, user_id)
    yield(result) if block_given?
    result
  end

  def store(user_id, event)
    result = op_event(:store, user_id, event)
    yield(result) if block_given?
    result
  end

  def remove(user_id, event)
    result = op_event(:remove, user_id, event)
    yield(result) if block_given?
    result
  end

  def wipe(user_id)
    result = op_feed(:wipe, user_id)
    yield(result) if block_given?
    result
  end

  def users(user_ids = [])
    user_ids.each do |id|
      yield(id)
    end
  end

  context '#store' do
    let(:user_id) { 99119911991199 }
    let(:activity) { SimpleFeed.tested_feed.user_activity(user_id) }

    context 'storing and removing events' do
      it('returns valid responses back from each operation') do
        users [user_id] do |id|
          store(id, events[0]) { |result| expect(result[id]).to eq(true) }
          store(id, events[1]) { |result| expect(result[id]).to eq(true) }
          all(id) { |result| expect(result[id].size).to eq(2) }
          total(id) { |result| expect(result[id]).to eq(2) }
          store(id, events[0]) { |result| expect(result[id]).to eq(false) }
          remove(id, events[0]) { |result| expect(result[id]).to eq(true) }
          remove(id, events[0]) { |result| expect(result[id]).to eq(false) }
        end
      end
    end

    context 'adding two events' do
      before do
        users [user_id] do |id|
          store id, events[0] do |results|
            store id, events[1] do |_results|
              expect(_results[id]).to eq(true)
            end
            expect(results[id]).to eq(true)
          end
        end
      end

      it('has two events') { check_counts(user_id, 2, 2) }

      context '#remove' do
        context 'one event' do
          it('has one event left') do
            expect(op_event(:remove, user_id, events[1])[user_id]).to_not be_nil
            check_counts(user_id, 1, 1)
          end
        end

        context 'non-existing event' do
          it 'has one event left still' do
            expect(op_feed(:all, user_id)[user_id].size).to eq(2)
            expect(op_event(:remove, user_id, events[1])[user_id]).to eq(true)
            expect(op_event(:remove, user_id, events[1])[user_id]).to eq(false)
            check_counts(user_id, 1, 1)
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
end
