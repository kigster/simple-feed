# frozen_string_literal: true

require 'spec_helper'

FROZEN_TIME = Time.now.freeze

Kernel.module_eval do
  def at(seconds = 0)
    FROZEN_TIME - 3600 + seconds
  end
end

shared_context :event_matrix do
  let(:consumer_id) { 1_020_945 }

  unless defined?(EVENT_MATRIX)
    EVENT_MATRIX = [
      ['Seth wanted to be The Boss.', at(1)],
      ['But Andy pooped on Debra\'s desk.', at(6)],
      ['Then Andy met The Giant Fish and f$$ked its brains out.', at(4)],
    ].freeze
  end

  let(:events) {
    EVENT_MATRIX.map do |args|
      ::SimpleFeed::EventTuple.new(data: args.first,
                              at:    args.last)
    end
  }

  let(:event) { events[0] }
end
