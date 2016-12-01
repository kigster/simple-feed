require 'spec_helper'

FROZEN_TIME = Time.now.freeze

Kernel.module_eval do
  def at(seconds = 0)
    FROZEN_TIME - 3600 + seconds
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

  let(:events) {
    EVENT_MATRIX.map do |args|
      ::SimpleFeed::Event.new(value:   args.first,
                              at:      args.last)
    end
  }

  let(:event) { events[0] }
  let(:another_event) { events[1] }
end
