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

  let(:user_id) { 99119911991199 }

  # UserActivity (or UsersActivity)
  let(:ua) { ->(id_or_array) { SimpleFeed.tested_feed.for(id_or_array) } }
  let(:verify) { ->(result, value) { expect(result[user_id]).to eq(value) } }

  let(:dsl) { SimpleFeed::DSL.new }

  # TODO: fix these fucking bastards

  context '#store' do
    context 'storing and removing events' do
      it 'returns valid responses back from each operation' do

        SimpleFeed.dsl(feed.for([user_id]),
                       user_id: user_id,
                       events: events,
                       verify: verify) do |*|

          store(event: events[1])
          wipe { |r| verify[r, true] }
          wipe { |r| verify[r, false] }
          store(event: events[1]) { |r| verify[r, true] }
          store(event: events[0]) { |r| verify[r, true] }
          total_count { |r| verify[r, 2] }
          store(event: events[0]) { |r| verify[r, false] }
          total_count { |r| verify[r, 2] }
          # remove(event: events[0]) { |r| verify[r][true] }
          # remove(event: events[0]) { |r| verify[r][false] }
        end
      end
    end
    #
    # context 'adding two events' do
    #   before do
    #     users [user_id] do |id|
    #       store ua[id], events[1]
    #       store ua[id], events[0]
    #       total_count ua[id] { |result| expect(result[id]).to eq(2) }
    #     end
    #   end
    #
    #   xit('has two events') { check_counts(user_id, 2, 2) }
    #
    #   context '#remove' do
    #     context 'one event' do
    #       it('has one event left') do
    #         remove ua[user_id], event { |result| expect(result).to_not be_nil }
    #         check_counts(user_id, 1, 1)
    #       end
    #     end
    #
    #     context 'non-existing event' do
    #       it 'has one event left still' do
    #         remove ua[user_id], events[1] { |result| expect(result[user_id]).to eq(true) }
    #         remove ua[user_id], events[1] { |result| expect(result[user_id]).to eq(false) }
    #         check_counts(user_id, 1, 1)
    #       end
    #     end
    #   end
    #

    # context '#paginate' do
    #   let(:ts) { Time.now }
    #   it 'resets last read, and returns the first event as page 1' do
    #     SimpleFeed.dsl(feed.for([user_id]), events: events, ts: ts) do |*|
    #       reset_last_read                 { |r| verify[r][ts] }
    #       paginate(page: 1, per_page: 1)  { |r| verify[r][false]}
    #     end
    #   end
    # end
  end
end
