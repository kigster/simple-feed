require 'spec_helper'
require 'redis'
require 'simplefeed/providers/redis/stats'

RSpec.describe SimpleFeed::Providers::Redis::Stats do

  let(:redis_db) { 7 }
  let(:redis) { Redis.new db: redis_db }
  subject(:stats) { described_class.new(redis) }

  before do
    redis.flushdb
    redis.hset('myhash', 'name', 'konstantin')
  end

  context 'class-level boot stats' do
    subject { stats.class.boot_info }
    its(:uptime_in_seconds) { should eq(26) }
    its(:used_memory) { should eq 1008384 }
  end

  context 'current redis-info' do
    subject { stats.info }
    its(:uptime_in_seconds) { should be >= 0 }
    its(:used_memory) { should be >= 1000000 }
    its([:dbstats, '7']) { should include({'keys' => 1})}
  end

  its(:used_memory_at_boot) { should eq(1008384)}
  its(:used_memory_since_boot) { should be > 0}

end
