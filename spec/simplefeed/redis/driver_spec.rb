require 'spec_helper'
require 'redis/connection/hiredis'
require 'connection_pool'

RSpec.describe SimpleFeed::Redis::Driver do
  class RedisAdapter
    include SimpleFeed::Redis::Driver
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

  context 'passing :pool directly' do
    let(:adapter) { RedisAdapter.new(pool: ConnectionPool.new(size: 2) { Redis.new }) }
    include_examples :validate_adapter
  end
  context 'passing :redis as a proc' do
    let(:adapter) { RedisAdapter.new(redis: -> { Redis.new }, pool_size: 2) }
    include_examples :validate_adapter
  end
  context 'passing :redis preinstantiated' do
    let(:adapter) { RedisAdapter.new(redis: Redis.new) }
    include_examples :validate_adapter
  end
  context 'passing :redis via a hash' do
    let(:adapter) { RedisAdapter.new(redis: { host: 'localhost', port: 6379, db: 1, timeout: 0.2 }, pool_size: 1) }
    include_examples :validate_adapter
  end
end
