require 'spec_helper'

RSpec.describe SimpleFeed::Event do

  let(:event_type) { described_class }

  let(:event1) { event_type.new(value: '1', at: Time.now) }
  let(:event2) { event_type.new(value: '2', at: Time.now - 10) }
  let(:event3) { event_type.new(value: '3', at: Time.now + 10) }

  let(:events_manually_sorted) { [event3, event1, event2] }

  let(:ts) { event1.at }

  context '#initialize' do
    let(:args) { nil }
    let(:opts) { {} }

    subject { event_type.new(*args, **opts) }

    it('should raise error when incomplete') { expect { subject }.to raise_error(ArgumentError) }

    let(:expected_timestamp) { ts }
    let(:expected_value) { 'hello' }

    shared_examples(:validate_event_constructor) do
      its(:value) { should eq expected_value }
      its(:at) { should eq expected_timestamp }
    end
    context 'when *args are provided' do
      let(:args) { ['hello', ts] }
      include_examples(:validate_event_constructor)
    end
    context 'when **opts are provided' do
      let(:opts) { { value: 'hello', at: ts } }
      include_examples(:validate_event_constructor)
    end
    context 'when both *args and *opts are provided' do
      let(:args) { ['hello', ts ] }
      let(:opts) { { value: 'bye', at: ts - 100 } }
      include_examples(:validate_event_constructor)
    end
    context 'when partial *args and *opts are provided' do
      let(:args) { ['hello' ] }
      let(:opts) { { value: 'bye', at: ts } }
      include_examples(:validate_event_constructor)
    end
    context 'when partial *args and *opts are provided' do
      let(:args) { ['hello' ] }
      let(:opts) { { at: ts } }
      include_examples(:validate_event_constructor)
    end
  end

  context '#eql?' do
    let(:identical) { event_type.new(value: '1', at: ts) }
    let(:dupe) { identical.dup }

    it 'should make a duplicate equal' do
      expect(event1).to eq(dupe)
      expect(event1).to eq(identical)
    end

    it 'but should be separate objects' do
      expect(identical.object_id).not_to eq(dupe.object_id)
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
      should match(/#{at.to_f}/)
      should match(/#{value}/)
      should include(time.to_s)
    end

    its(:to_color_s) do
      should match(/#{at.to_f}/)
      should match(/#{value}/)
      should include(time.to_s)
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
