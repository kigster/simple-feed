require 'spec_helper'

describe 'SimpleFeed::UserActivity' do

  let!(:feed) { SimpleFeed::Feed.new(:test) }

  before do
    feed.configure do |f|
      f.provider = SimpleFeed::Fixtures.mock_provider_props
      f.per_page = 2
      f.max_size = 10
    end
  end

  let!(:provider_proxy) { feed.provider }
  let!(:provider) { provider_proxy.provider }

  let(:user_id) { 19009845 }

  let(:user_activity) { SimpleFeed::UserActivity.new(user_id: user_id, feed: feed) }

  context 'method delegation' do
    SimpleFeed::Providers::REQUIRED_METHODS.each do |m|
      it "should delegate method #{m}" do
        expect(provider).to receive(m).with(user_id: user_id, hello: :goodbye)
        user_activity.send(m, hello: :goodbye)
      end
    end
  end
end
