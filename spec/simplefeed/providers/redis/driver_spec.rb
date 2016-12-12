require 'spec_helper'
require 'redis/connection/hiredis'
require 'connection_pool'
require 'simplefeed/providers/redis/driver'

RSpec.describe SimpleFeed::Providers::Redis::Driver do
  class RedisAdapter
    include SimpleFeed::Providers::Redis::Driver
  end

  shared_examples(:validate_adapter) do
    let(:success) { 'OK' }

    context '#set & #get' do
      before { adapter.set(key, value) }
      it 'should have the key/value set' do
        expect(adapter.get(key)).to eq(value)
        expect(adapter.exists(key)).to eq(true)
        expect(adapter.delete(key)).to eq(1)
        expect(adapter.exists(key)).to eq(false)
      end
    end

    context '#set & #get pipelined' do
      before { adapter.set(key, value) }
      it 'should have the key/value set' do
        adapter.with_pipelined do |r|
          @set    = r.set('another', 'value')
          @get    = r.get(key)
          @exists = r.exists(key)
          @rm     = r.del(key)
        end
        expect(@set.value).to eq(success)
        expect(@get.value).to eq(value)
        expect(@exists.value).to eq(true)
        expect(@rm.value).to eq(1)
      end
    end

    context '#zadd & #zrange' do
      before do
        adapter.rm(key)
        adapter.zadd(key, score, value)
      end
      it 'should manipulate an ordered set' do
        expect(adapter.zrange(key, 0, 1)).to eq([value])
        expect(adapter.exists?(key)).to eq(true)
        expect(adapter.rm(key)).to eq(1)
        expect(adapter.exists(key)).to eq(false)
      end
    end
  end

  let(:key) { 'hello' }
  let(:value) { 'good bye' }
  let(:score) { Time.now.to_i }
  let!(:redis) { Redis.new }

  context 'passing :pool directly' do
    let(:adapter) { RedisAdapter.new(pool: ConnectionPool.new(size: 2) { redis }) }
    include_examples :validate_adapter
  end
  context 'passing :redis as a proc' do
    let(:adapter) { RedisAdapter.new(redis: -> { Redis.new }, pool_size: 2) }
    include_examples :validate_adapter
  end
  context 'passing :redis pre-instantiated' do
    let(:adapter) { RedisAdapter.new(redis: Redis.new) }
    include_examples :validate_adapter
  end
  context 'passing :redis via a hash' do
    let(:adapter) { RedisAdapter.new(redis: { host: 'localhost', port: 6379, db: 1, timeout: 0.2 }, pool_size: 1) }
    include_examples :validate_adapter
  end
  context 'retrying an operation' do
    let(:adapter) { RedisAdapter.new(redis: redis , pool_size: 1) }
    it 'should retry and succeed' do
      redis.del('retry')
      expect(redis).to receive(:set).and_raise(::Redis::BaseConnectionError).once
      expect(redis).to receive(:set).with('retry', 'connection')
      adapter.set('retry', 'connection')
    end
  end
  context 'LoggingRedis' do
    let(:adapter) { RedisAdapter.new(redis: redis , pool_size: 1) }
    it 'should print out each redis operation to STDERR' do
      expect(SimpleFeed::Providers::Redis::Driver::LoggingRedis.stream).to receive(:printf).at_least(15).times
      expect(SimpleFeed::Providers::Redis::Driver::LoggingRedis.stream).to receive(:puts).exactly(3).times

      SimpleFeed::Providers::Redis.with_debug do
        adapter.with_redis do |redis|
          expect(redis.set('hokey', 'pokey')).to eq 'OK'
          expect(redis.get('hokey')).to eq 'pokey'
          expect(redis.del('hokey')).to eq 1
        end
      end
    end
  end
end
