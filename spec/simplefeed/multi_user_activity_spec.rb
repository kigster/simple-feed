require 'spec_helper'

describe 'SimpleFeed::MultiUserActivity' do

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

  let(:user_id_1) { 19009845 }
  let(:user_id_2) { 32423049 }

  let(:user_ids) { [user_id_1, user_id_2] }
  let(:multi_user_activity) { feed.for(user_ids) }

  context 'method delegation' do
    it 'should correctly assign the type of multi_user_activity' do
      expect(multi_user_activity.class).to eq(SimpleFeed::MultiUserActivity)
      expect(multi_user_activity.user_ids).to eq(user_ids)
    end


    context 'Enumeration of users' do
      it 'should enumerate users' do
        multi_user_activity.each do |user_id|
          expect(user_ids.include?(user_id)).to be(true)
        end
      end
    end

    context 'calling through to provider' do
      let(:provider_must_receive) {
        ->(method, **opts) {
          expect(opts).to_not be_empty
          expect(provider).to receive(method).
            with(user_ids: user_ids, **opts).
            and_return(SimpleFeed::Response.new({
                                                  user_ids[0] => true,
                                                  user_ids[0] => true
                                                }))
        }
      }

      let!(:opts) { { hello: :goodbye } }

      SimpleFeed::Providers::REQUIRED_METHODS.each do |m|

        context "method #{m}" do
          before do
            provider_must_receive[m, **opts]
          end

          it 'should call the provider' do
            multi_user_activity.send(m, **opts)
          end

          context '#Enumeration' do
            it 'should enumerate response' do
              multi_user_activity.send(m, **opts).each do |user_id, result|
                expect(user_ids.include?(user_id)).to be(true)
                expect(result).to be(true)
              end
            end
          end
        end
      end
    end
  end
end
