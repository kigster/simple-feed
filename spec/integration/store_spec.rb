require 'spec_helper'

# We'll be generating various times only seconds apart
def at(sec)
  Time.mktime(2016, 12, 01, 10, 00, sec)
end

context 'Integration ➞ Storing Events' do
  let(:feed) { SimpleFeed::Fixtures.follow_feed }

  it 'should be correctly defined' do
    expect(feed).to_not be_nil
    expect(feed).to be_kind_of(SimpleFeed::Feed)
    expect(feed.name).to eq :follow_feed
    expect(feed.provider).to be_kind_of(SimpleFeed::ProviderProxy)
  end

  let(:user_id) { 1020945 }

  let(:event_matrix) { [
    ['John was reported missing', at(1)],
    ['{ "comment_id" : 1, "author_id": 1948985 }', at(6)],
    ['Your wife had sent you divorce papers', at(4)],
  ] }

  let(:events) {
    event_matrix.map do |args|
      SimpleFeed::Event.new(user_id: user_id, value: args.first, at: args.last )
    end
  }
  let(:first_event) { events.first }
  let(:last_event) { events.last }

  it 'should define events' do
    expect(events.size).to eq(3)
    expect(events.last.value).to eq(event_matrix[2][0])
    expect(events.last.at).to eq(event_matrix[2][1])
  end


end
