require 'spec_helper'
require 'simplefeed/providers/hash_provider'

RSpec.describe 'SimpleFeed::Providers::HashProvider' do

  subject(:feed) { SimpleFeed.define(:hash_feed) { |f| f.max_size = 5 } }

  context '#initialize' do
    it('sets default per_page') { expect(feed.max_size).to eq(5) }
  end

  before do
    feed.configure do |f|
      f.provider = SimpleFeed::Providers::HashProvider.new
    end
  end

  context '#storing events' do
    let(:user_id) { 99119911991199 }
    include_examples :event_matrix
    let(:activity) { SimpleFeed.hash_feed.user_activity(user_id) }

    before do
      activity.wipe
      expect(activity.events.size).to eq(0)

      activity.store(value: events[0].value,
                     at:    events[0].at)
    end

    it('should correctly set total_count') { expect(activity.total_count).to eq(1) }
    it('should correctly set unread_counts') { expect(activity.unread_count).to eq(1) }
  end
end
