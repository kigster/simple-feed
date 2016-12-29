require 'spec_helper'
require 'colored2'
require 'simplefeed/dsl'

def ensure_descending(r)
  last_event = nil
  r.each do |event|
    if last_event
      expect(event.time).to be <= last_event.time
    end
    last_event = event
  end
end

# Requires the following variables set:
#  * provider_opts

shared_examples 'a provider' do
  include_context :event_matrix

  subject(:feed) {
    SimpleFeed.define(:tested_feed) do |f|
      f.max_size = 5
      f.provider = described_class.new(provider_opts)
    end
  }

  let(:provider) { feed.provider.provider }
  let(:user_id) { 99119911 }
  let(:activity) { feed.activity(user_id) }

  # Reset the feed with a wipe, and ensure the size is zero
  before { with_activity(activity) { wipe; total_count { |r| expect(r).to eq(0) } } }

  context '#store' do
    context 'new events' do
      it 'returns valid responses back from each operation' do
        with_activity(activity, events: events) do
          store(events.first) { |r| expect(r).to eq(true) }
          total_count { |r| expect(r).to eq(1) }

          store(events.last) { |r| expect(r).to eq(true) }
          total_count { |r| expect(r).to eq(2) }
        end
      end
    end

    context 'storing new events' do
      it 'returns valid responses back from each operation' do
        with_activity(activity, events: events) do
          store(events.first) { |r| expect(r).to eq(true) }
          store(events.first) { |r| expect(r).to eq(false) }

          store(events.last) { |r| expect(r).to eq(true) }
          store(events.last) { |r| expect(r).to eq(false) }
        end
      end
    end

    context 'storing and removing events' do
      before do
        with_activity(activity, events: events) do
          store(events.first) { |r| expect(r).to eq(true) }
          store(events.last) { |r| expect(r).to eq(true) }
          total_count { |r| expect(r).to eq(2) }
        end
      end

      context '#delete' do
        it('with event as an argument') do
          with_activity(activity, events: events) do
            delete(events.first) { |r| expect(r).to eq(true) }
            total_count { |r| expect(r).to eq(1) }
          end
        end
        it('with event value as an argument') do
          with_activity(activity, events: events) do
            delete(events.first.value) { |r| expect(r).to eq(true) }
            total_count { |r| expect(r).to eq(1) }
          end
        end
      end

      context '#delete_if' do
        let(:activity) { feed.activity(user_id) }

        it 'should delete events that match' do
          activity.wipe
          events.each do |event|
            expect(activity.store(event: event)).to eq(true)
          end
          expect(activity.total_count).to eq(3)
          deleted_events = activity.delete_if do |event_to_delete, *|
            event_to_delete == events.first
          end
          expect(activity.total_count).to eq(2)
          expect(deleted_events).to eq([events.first])
          expect(activity.fetch).to include(events.last)
          expect(activity.fetch).not_to include(events.first)
        end
      end

      context 'hitting #max_size of the feed' do
        it('pushes the oldest one out') do
          with_activity(activity, events: events) do
            wipe
            # The next one resets the time
            store(value: 'new story right now') { |r| expect(r).to be true }
            store(value: 'old one', at: Time.now - 5.0) { |r| expect(r).to be(true) }
            store(value: 'older one', at: Time.now - 6.0) { |r| expect(r).to be(true) }
            store(value: 'one just now') { |r| expect(r).to be(true) }
            store(value: 'the super old one', at: Time.now - 20000.0) { |r| expect(r).to be(true) }
            store(value: 'and in the future', at: Time.now + 10.0) { |r| expect(r).to be(true) }

            fetch do |r|
              ensure_descending(r)
              expect(r.size).to eq(5)
              expect(r.map(&:value)).not_to include('the oldest')
              expect(r.map(&:value)).to include('old one')
              expect(r.map(&:value).first).to eq('and in the future')
            end
          end

        end
      end

      context '#unread_count, #paginate and #last_read' do
        it 'correctly resets the last_read and unread_count after paginate' do
          with_activity(activity, events: events) do
            wipe

            current_time = Time.now
            reset_last_read at: current_time

            last_read { |r| expect(r.to_f).to be_within(0.001).of(current_time.to_f) }

            # The next one resets the time
            store(value: 'new story right now') { |r| expect(r).to be true }
            store(value: 'old one', at: current_time - 5.0) { |r| expect(r).to be(true) }
            store(value: 'older one', at: current_time - 6.0) { |r| expect(r).to be(true) }

            # unread count at this point is 1 because only the 'new story right now' is more recent
            # then the unread flag
            unread_count { |r| expect(r).to eq(1) }

            last_read { |r| expect(r.to_f).to be_within(0.001).of(current_time.to_f) }

            paginate(page: 1, per_page: 1) do |r|
              expect(r.size).to eq(1)
              expect(r.first.value).to eq('new story right now')
            end

            paginate(page: 1, per_page: 1, with_total: true, reset_last_read: true) do |r|
              expect(r[:events].size).to eq(1)
              expect(r[:total_count]).to eq(3)
            end

            time_then = Time.now

            last_read { |r| expect(r.to_f).to be > current_time.to_f }
            last_read { |r| expect(r.to_f).to be < time_then.to_f }

            # now that we've read the feed...
            unread_count { |r| expect(r).to be == 0 }

            last_read { |r| expect(r.to_f).to be < time_then.to_f }

            store(value: 'and then one right now',) { |r| expect(r).to be(true) }
            unread_count { |r| expect(r).to be == 1 }

            store(value: 'and then one just ahead of it', at: time_then + 3) { |r| expect(r).to be(true) }
            unread_count { |r| expect(r).to be == 2 }

            store(value: 'and even then one more', at: time_then + 10) { |r| expect(r).to be(true) }
            unread_count { |r| expect(r).to be == 3 }

            store(value: 'some other future ', at: time_then + 30) { |r| expect(r).to be(true) }
            unread_count { |r| expect(r).to be == 4 }

            fetch { |r| expect(r.size).to eq 5 }

            fetch(since: last_read) { |r| expect(r.size).to eq 4 }
            fetch(since: time_then + 15) { |r| expect(r.size).to eq 1 }

            unread_count { |r| expect(r).to be == 4 }

            fetch(since: :unread, reset_last_read: true) { |r| expect(r.size).to eq 4 }

            # only because we have 3 items in the future now
            unread_count { |r| expect(r).to be == 3 }
            total_count { |r| expect(r).to be == 5 }

            # color_dump
          end
        end
      end

      context '#fetch' do
        it 'fetches all elements sorted by time desc' do
          with_activity(activity, events: events) do

            reset_last_read

            store(value: 'new story') { |r| expect(r).to be(true) }
            store(value: 'and another', at: Time.now - 7200) { |r| expect(r).to be(true) }
            store(value: 'and one more') { |r| expect(r).to be(true) }
            store(value: 'and two more') { |r| expect(r).to be(true) }

            fetch { |r| ensure_descending(r) }
          end
        end
      end
    end

    context '#namespace' do
      let(:feed_proc) { ->(namespace) {
        SimpleFeed.define("#{namespace}") do |f|
          f.max_size  = 5
          f.namespace = namespace
          f.provider  = described_class.new(provider_opts)
        end
      } }

      let(:feed_ns1) { feed_proc.call(:ns1) }
      let(:feed_ns2) { feed_proc.call(:ns2) }

      let(:ua_ns1) { feed_ns1.activity(user_id) }
      let(:ua_ns2) { feed_ns2.activity(user_id) }

      before do
        ua_ns1.wipe
        ua_ns1.store(value: 'ns1')

        ua_ns2.wipe
        ua_ns2.store(value: 'ns2')
      end

      it 'properly sets namespace on each feed' do
        expect(feed_ns1.namespace).to eq(:ns1)
        expect(feed_ns2.namespace).to eq(:ns2)
      end

      it 'does not conflict if namespaces are distinct' do
        expect(ua_ns1.fetch.map(&:value)).to eq(%w(ns1))
        expect(ua_ns2.fetch.map(&:value)).to eq(%w(ns2))
      end
    end

    context 'additional methods' do
      it '#total_memory_bytes' do
        expect(provider.total_memory_bytes).to be > 0
      end
      it '#total_users' do
        expect(provider.total_users).to eq(1)
      end
    end

  end
end
