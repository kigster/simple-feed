require 'spec_helper'

describe 'SimpleFeed::Providers' do

  class ActivityProvider
  end

  subject(:activity) { ActivityProvider.new }

  context 'consumer methods' do
    before do
      ActivityProvider.include(::SimpleFeed::Providers::ConsumerMethods)
    end

    it { is_expected.to respond_to :paginate }
  end

  context 'publisher methods' do
    before do
      ActivityProvider.include(::SimpleFeed::Providers::PublisherMethods)
    end

    it { is_expected.to respond_to :publish }
  end
end
