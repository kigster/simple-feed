require 'spec_helper'
require 'simplefeed/providers/hash_provider'

RSpec.describe SimpleFeed::Providers::HashProvider do

  before :all do
    SimpleFeed.registry.delete(:tested_feed)
  end

  let(:provider_args) { [] }
  let(:provider_opts) { {} }
  let(:provider_block) { nil }

  it_behaves_like 'a provider'
end
