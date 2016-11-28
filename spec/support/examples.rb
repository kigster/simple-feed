require 'spec_helper'

Kernel.module_eval do
  def at(seconds = 0)
    Time.mktime(2017, 01, 01, 0, 0, seconds)
  end
end

shared_context :event_matrix do
  let(:user_id) { 1020945 }

  unless defined?(EVENT_MATRIX)
    EVENT_MATRIX = [
      ['John was reported missing.', at(1)],
      ['Andy pooped on Debra\'s desk.', at(6)],
      ['Your assistant had sent you divorce papers, although you were not married.', at(4)],
    ]
  end

  let!(:events) {
    EVENT_MATRIX.map do |args|
      ::SimpleFeed::Event.new(user_id: user_id,
                              value:   args.first,
                              at:      args.last)
    end
  }

  let!(:event) { events[0] }
  let!(:another_event) { events[1] }
end
