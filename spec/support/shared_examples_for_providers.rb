require 'spec_helper'
require 'colored2'
require 'simplefeed/dsl'

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

  let(:user_id) { 99119911 }
  let(:ua) { ->(id_or_array) { SimpleFeed.tested_feed.activity(id_or_array) } }
  let(:dsl) { SimpleFeed::DSL.new }

  context '#store' do
    context 'storing events and wiping feed' do
      it 'returns valid responses back from each operation' do
        SimpleFeed.dsl(feed.activity(user_id),
                       events:  events,
                       context: self) do |*|

          wipe
          total_count { |r| expect(r).to eq(0) }

          store(events.first) { |r| expect(r).to eq(true) }
          wipe { |r| expect(r).to eq(true) }

          store(events.first) { |r| expect(r).to eq(true) }
          store(events.last) { |r| expect(r).to eq(true) }

          total_count { |r| expect(r).to eq(2) }
        end
      end
    end

    context 'storing and removing events' do
      before do
        SimpleFeed.dsl(feed.activity(user_id),
                       events:  events,
                       context: self) do |*|
          wipe

          store(events.first) { |r| expect(r).to eq(true) }
          store(events.first) { |r| expect(r).to eq(false) }
          store(events.last) { |r| expect(r).to eq(true) }
          store(events.last) { |r| expect(r).to eq(false) }
        end
      end

      context '#delete' do
        it('has one event left') do
          SimpleFeed.dsl(feed.activity(user_id),
                         events:  events,
                         context: self) do |*|

            delete(events.first) { |r| expect(r).to eq(true) }
            total_count { |r| expect(r).to eq(1) }
          end
        end
      end

      context '#delete_if' do
        let(:activity) { feed.activity(user_id) }
        it 'should delete events that match' do
          expect(activity.total_count).to eq(2)
          activity.delete_if do |user_id, evt|
            evt == events.first
          end
          expect(activity.total_count).to eq(1)
          expect(activity.fetch).to include(events.last)
          expect(activity.fetch).not_to include(events.first)
        end
      end

      context 'hitting #max_size of the feed' do
        it('pushes the latest one or') do
          SimpleFeed.dsl(feed.activity(user_id),
                         events:  events,
                         context: self) do |*|

            total_count { |r| expect(r).to eq(2) }

            4.times do |i|
              store(value: "number #{i}", at: Time.now + 3600) { |r| expect(r).to eq(true) }
            end

            total_count { |r| expect(r).to eq(5) }

            fetch { |r| expect(r.size).to eq(5) }
            fetch { |r| expect(r).to include(events[2]) }
            fetch { |r| expect(r).not_to include(events[1]) }
          end

          feed.activity(user_id).fetch.each do |event|
            expect(event).to be_kind_of(::SimpleFeed::Event)
          end
        end
      end

      context '#paginate' do
        let(:ts) { Time.now }
        it 'resets last read, and returns the first event as page 1' do
          SimpleFeed.dsl(feed.activity(user_id),
                         events:  events,
                         context: self) do |*|
            unread_count { |r| expect(r).to eq(2) }
            reset_last_read { |r| expect(r.to_f).to be_within(0.1).of(Time.now.to_f) }
            unread_count { |r| expect(r).to eq(0) }
          end
        end
      end
    end
  end
end
