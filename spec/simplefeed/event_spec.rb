require 'spec_helper'

RSpec.describe SimpleFeed::Event do

  let(:event1) { described_class.new(value: '1', at: Time.now) }
  let(:event2) { described_class.new(value: '2', at: Time.now - 10) }
  let(:event3) { described_class.new(value: '3', at: Time.now + 10) }
  let(:events_manually_sorted) { [event3, event1, event2] }

  context '#eql?' do
    let(:identical) { described_class.new(value: '1', at: Time.now - 60) }

    it 'should make a duplicate equal' do
      expect(event1).to eq(event1.dup)
    end

    it 'should be only using value in equality and in uniqeness' do
      expect(event1).to eq(identical)
      expect(event1.hash).to eq(identical.hash)
    end

  end

  context '#to_s #inspect and #to_json' do
    subject { event1 }
    let(:at) { event1.at }
    let(:value) { event1.value }
    let(:time) { Time.at(at) }
    let(:expected_json) { { value: value, at: at, time: time }.to_json }

    its(:to_json) { should eq expected_json }
    its(:to_s) do
      should match /#{at.to_f}/
      should match /#{value}/
      should match /time/
      should match /#{time}/
    end
  end
  context '#to_json' do
    it 'should properly generate JSON' do

    end
  end

  context '#sorting' do
    it 'should correctly compare to another event by time' do
      expect(event1 <=> event2).to eq(-1) # more recent event first
    end

    context 'inside a sorted set' do
      let(:events) { SortedSet.new }
      before do
        events << event1
        events << event2
        events << event3
      end
      it 'should already exist in the set' do
        expect(events.size).to eq(3)
        expect(events.include?(event2)).to eq(true)
      end
      it 'should automatically sort events based on Time desc' do
        expect(events.to_a.map(&:value)).to eq(events_manually_sorted.map(&:value))
      end
    end
  end
end
