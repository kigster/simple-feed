# frozen_string_literal: true

require 'spec_helper'
require 'simplefeed/providers/hash/provider'

RSpec.describe SimpleFeed::Providers::Hash::Provider do
  it_behaves_like 'a valid provider',
                  provider_args: {},
                  more_users:    'hash-me-honey',
                  provider:      described_class
end
