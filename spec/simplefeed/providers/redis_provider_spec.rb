require 'spec_helper'
require 'simplefeed/providers/redis_provider'

RSpec.describe SimpleFeed::Providers::RedisProvider do
  it_behaves_like 'a provider'
end
