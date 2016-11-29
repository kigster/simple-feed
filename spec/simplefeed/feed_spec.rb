require 'spec_helper'

describe 'SimpleFeed::Feed' do

  context '#initialize' do
    subject(:feed) { SimpleFeed::Feed.new(:test) }
    it('sets default per_page') { expect(feed.per_page).to eq(50) }
    it('sets default max_size') { expect(feed.max_size).to eq(1000) }
  end

  context '#configure' do
    subject(:feed) { SimpleFeed::Feed.new(:test) }
    before do
      feed.configure('provider' => SimpleFeed::Fixtures.mock_provider_props) do |f|
        f.per_page = 2
        f.max_size = 10
      end
    end

    it('sets per_page') { expect(feed.per_page).to eq(2) }
    it('sets max_size') { expect(feed.max_size).to eq(10) }
    it('sets provider proxy') { expect(feed.provider.class).to eq(SimpleFeed::Providers::Proxy) }
    it('sets proxys provider') { expect(feed.provider.provider.class).to eq(SimpleFeed::MockProvider) }
    it('has feed set on provider') { expect(feed.provider.provider.feed).to eq(feed) }

    context 'with a pre configured provider' do
      let(:pre_instantiated_provider) { SimpleFeed::Providers::Proxy.from(SimpleFeed::Fixtures.mock_provider_props).provider }
      let(:provider) { SimpleFeed::Providers::Proxy.from(pre_instantiated_provider).provider }

      it 'should be one and the same' do
        expect(pre_instantiated_provider).to eq(provider)
      end

    end
  end

end
