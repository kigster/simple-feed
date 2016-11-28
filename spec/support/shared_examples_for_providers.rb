require 'spec_helper'
require 'colored2'

module Shortcuts
  SimpleFeed::Providers.define_provider_methods(self) do |instance, method, *args, **opts, &block|
    activity = args[0]
    event    = args[1]
    debug    = false

    printf " #{instance.feed.name.to_s.blue}.#{sprintf("%-16s", method.to_s).magenta}(#{opts.to_s.blue}) \n\t\t\t" if debug

    opts.merge!(event: event) if event
    response = activity.send(method, **opts)
    puts '———> ' + response.inspect.green if debug
    yield(response) if block_given?
    response
  end

  def check_counts(user_id, total, unread = total)
    #puts 'total: ' + total_count(activity[user_id]).inspect
    expect(total_count(activity[user_id])).to eq(total)
    #puts 'unread: ' + unread_count(activity[user_id]).inspect
    # expect(unread_count(activity[user_id])).to eq(unread)
  end

  def users(user_ids = [])
    user_ids.each do |id|
      yield(id)
    end
  end
end

# Requires the following variables set:
#  * provider_opts

shared_examples 'a provider' do
  include Shortcuts

  subject(:feed) {
    SimpleFeed.define(:tested_feed) do |f|
      f.max_size = 5
      f.provider = described_class.new(provider_opts)
    end
  }

  before { feed }
  include_context :event_matrix

  let(:user_id) { 99119911991199 }
  let(:activity) { ->(user_id) { SimpleFeed.tested_feed.for(user_id) } }

  context '#store' do

    context 'storing and removing events' do
      it('returns valid responses back from each operation') do
        users [user_id] do |id|
          wipe activity[id]
          store activity[id], event { |result| expect(result[id]).to eq(true) }
          store activity[id], another_event { |result| expect(result[id]).to eq(true) }
          all activity[id] { |result| expect(result[id].size).to eq(2) }
          total_count activity[id] { |result| expect(result[id]).to eq(2) }
          store activity[id], event { |result| expect(result[id]).to eq(false) }
          remove activity[id], event { |result| expect(result[id]).to eq(true) }
          remove activity[id], event { |result| expect(result[id]).to eq(false) }
        end
      end
    end

    context 'adding two events' do
      before do
        users [user_id] do |id|
          store activity[id], events[1]
          store activity[id], events[0]
          total_count activity[id] { |result| expect(result[id]).to eq(2) }
        end
      end

      xit('has two events') { check_counts(user_id, 2, 2) }

      context '#remove' do
        context 'one event' do
          it('has one event left') do
            remove activity[user_id], event { |result| expect(result).to_not be_nil }
            check_counts(user_id, 1, 1)
          end
        end

        context 'non-existing event' do
          it 'has one event left still' do
            all activity[user_id] { |result| expect(result[user_id].size).to eq(2) }
            remove activity[user_id], events[1] { |result| expect(result[user_id]).to eq(true) }
            remove activity[user_id], events[1] { |result| expect(result[user_id]).to eq(false) }
            check_counts(user_id, 1, 1)
          end
        end
      end

      context '#paginate' do
        let(:ts) { Time.now }
        it 'resets last read, and returns the first event as page 1' do
          reset_last_read(activity[user_id], at: ts) { |result| expect(result[user_id]).to eq(ts) }
          paginate(activity[user_id], page: 1, per_page: 1) { |result| expect(result[user_id]).to_not be_empty }
          last_read(activity[user_id]) { |result| expect(result[user_id]).not_to eq(ts) }
        end
      end
    end
  end
end
