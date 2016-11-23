require 'spec_helper'

RSpec.shared_examples :event_matrix do
  let(:user_id) { 1020945 }

  let(:event_matrix) { [
    ['John was reported missing.', at(1)],
    ['Andy pooped on Debra\'s desk.', at(6)],
    ['Your assistant had sent you divorce papers, although you were not married.', at(4)],
  ] }

  let(:events) {
    event_matrix.map do |args|
      SimpleFeed::Event.new(user_id: user_id,
                            value:   args.first,
                            at:      args.last)
    end
  }

  let(:first_event) { events.first }
  let(:last_event) { events.last }
end
