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

    context 'method #get' do
      it 'should fetch the same feed as defined' do
        expect(feed).to eq(fetched)
      end
    end
    context 'method named like the feed name' do
      it 'should fetch the feed' do
        expect(SimpleFeed.send(feed_name)).to eq(fetched)
      end

      it 'should raise NameError for a non-existing feed' do
        expect { SimpleFeed.send(:Wookie) }.to raise_error(NameError)
      end
    end
  end

  context 'self.provider' do
    context 'when provider is known' do
      let(:redis) { ::Redis.new }
      subject { SimpleFeed.provider(:redis, redis: redis, pool_size: 1) }

      it { is_expected.to be_kind_of(SimpleFeed::Providers::Redis::Provider) }
      its(:pool) { should be_kind_of(ConnectionPool) }
    end

    context 'when provider is unknown' do
      it 'should raise ArgumentError' do
        expect { SimpleFeed.provider(:unknown_provider) }.to raise_error(ArgumentError)
      end
    end
  end
end
