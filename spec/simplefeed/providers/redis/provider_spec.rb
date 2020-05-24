# frozen_string_literal: true

require 'spec_helper'
require 'simplefeed/providers/redis/provider'

RSpec.describe SimpleFeed::Providers::Redis::Provider do
  REDIS_PROVIDER_OPTS = {
    pool_size: 1,
    redis:     {
      host:    '127.0.0.1',
      port:    6379,
      db:      1,
      timeout: 0.2
    },
  }.freeze

  it_behaves_like 'a valid provider',
                  provider_args: REDIS_PROVIDER_OPTS,
                  more_users:    'horsing-around-monkey',
                  provider:      described_class
end
