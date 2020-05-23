# frozen_string_literal: true

require 'spec_helper'
require 'simplefeed/providers/hash/provider'

RSpec.describe SimpleFeed::Providers::Hash::Provider do
  before(:suite) { SimpleFeed.registry.delete(:tested_feed) }

  it_behaves_like 'a valid SimpleFeed backend provider',
                  provider_opts:    {},
                  optional_user_id: 'hash-me-honey',
                  provider_class:   described_class
end
