# frozen_string_literal: true

require 'spec_helper'

describe 'SimpleFeed::Activity::MultiUserActivity' do
  let!(:feed) { SimpleFeed::Feed.new(:test) }

  before do
    feed.configure do |f|
      f.provider = SimpleFeed::Fixtures.mock_provider_props
      f.per_page = 2
      f.max_size = 10
    end
  end

  let!(:provider_proxy) { feed.provider }
  let!(:provider) { provider_proxy.provider }

  let(:consumer_id_1) { 19_009_845 }
  let(:consumer_id_2) { 32_423_049 }

  let(:consumer_ids) { [consumer_id_1, consumer_id_2] }
  let(:user_activity) { feed.activity(consumer_ids) }

  context 'method delegation' do
    it 'should correctly assign the type of user_activity' do
      expect(user_activity.class).to eq(SimpleFeed::Activity::MultiUser)
      expect(user_activity.consumer_ids).to eq(consumer_ids)
    end

    context 'Enumeration of users' do
      it 'should enumerate users' do
        user_activity.each do |consumer_id|
          expect(consumer_ids.include?(consumer_id)).to be(true)
        end
      end
    end

    context 'calling through to provider' do
      let(:true_response) do
        SimpleFeed::Response.new({ consumer_id_1 => true, consumer_id_2 => true })
      end

      let(:provider_must_receive) {
        ->(method, **opts) {
          expect(opts).to_not be_empty
          expect(provider).to receive(method).with(consumer_ids: consumer_ids, **opts).
                                and_return(true_response)
        }
      }

      let!(:opts) { { hello: :goodbye } }

      SimpleFeed::Providers::REQUIRED_METHODS.each do |method|
        context "method #{method}" do
          before { provider_must_receive[method, **opts] }

          it('should call the provider') { user_activity.send(method, **opts) }

          context 'response' do
            subject { user_activity.send(method, **opts) }

            its(:class) { should be SimpleFeed::Response }
            its(:user_count) { should be 2 }

            it('should respond to #each') { is_expected.to respond_to(:each) }
            it(:each) { expect { |args| subject.each(&args) }.to yield_successive_args([consumer_id_1, true], [consumer_id_2, true]) }
          end
        end
      end
    end
  end
end
