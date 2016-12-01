require 'spec_helper'

RSpec.describe SimpleFeed::Event do
  context '#eql?' do
    let(:ts1) { Time.now }
    let(:ts2) { Time.now - 10 }

    let(:event1) { described_class.new(value: 'hello', at: ts1) }
    let(:event2) { described_class.new(value: 'hello', at: ts2) }

    it 'should make a duplicate equal' do
      expect(event1).to eq(event1.dup)
    end

    it 'should properly generate JSON' do
      expect(event1.to_json).to eq({ value: event1.value, at: event1.at }.to_json)
    end

    it 'should correctly compare to another event by time' do
      expect(event1 <=> event2).to eq(1) # more recent event first
    end

    it 'should be only using value in equality and in uniqeness' do
      expect(event1).to eq(event2)
      expect(event1.hash).to eq(event2.hash)
    end

    context 'inside a sorted set' do
      let(:events) { SortedSet.new }
      before do
        events << event1
        events << event2
      end
      it 'should already exist in the set' do
        expect(events.size).to eq(1)
        expect(events.include?(event2)).to eq(true)
      end
    end
  end
end
