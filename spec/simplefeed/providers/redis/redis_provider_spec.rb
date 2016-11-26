require 'spec_helper'
require 'simplefeed/providers/redis/provider'

RSpec.describe SimpleFeed::Providers::Redis::Provider do
  before :all do
    SimpleFeed.registry.delete(:tested_feed)
  end

  let(:provider_args) { nil }
  let(:provider_opts) { { redis: { host: 'localhost', port: 6379, db: 1, timeout: 0.2 }, pool_size: 1 } }
  let(:provider_block) { nil }

  it_behaves_like 'a provider'
end
