require 'spec_helper'

describe SimpleFeed do
  it 'has a version number' do
    expect(SimpleFeed::VERSION).not_to be nil
  end

  context 'self.define' do
    let(:feed_name) { :my_feed }
    let(:feed) { SimpleFeed.define(feed_name) { |f| f.max_size = 100 } }
    let(:fetched) { SimpleFeed.get(feed_name) }

    it 'should properly configure the feed' do
      expect(feed.max_size).to eq(100)
    end

    it 'should fetch the same feed as defined' do
      expect(feed).to eq(fetched)
    end

  end
end
