require 'spec_helper'

FROZEN_TIME = Time.now.freeze

Kernel.module_eval do
  def at(seconds = 0)
    FROZEN_TIME - 3600 + seconds
  end
end

shared_context :event_matrix do
  let(:user_id) { 1020945 }

  EVENT_MATRIX = [
    ['Seth wanted to be The Boss.', at(1)],
    ['But Andy pooped on Debra\'s desk.', at(6)],
    ['Then Andy met The Giant Fish and f$$ked its brains out.', at(4)],
  ] unless defined?(EVENT_MATRIX)

  let(:events) {
    EVENT_MATRIX.map do |args|
      ::SimpleFeed::Event.new(value:   args.first,
                              at:      args.last)
    end
  }

  let(:event) { events[0] }
end
