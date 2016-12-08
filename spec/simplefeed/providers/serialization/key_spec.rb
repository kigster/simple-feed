require 'spec_helper'

RSpec.describe SimpleFeed::Providers::Serialization::Key do
  let(:user_id) { 199929993999 }
  let(:config) { {} }
  let(:namespace) { :namespace }
  subject { described_class.new(user_id, namespace, config) }

  context 'initialization' do
    context 'with a namespace' do
      its(:short_id) { should eq '3wepSyz' }
      its(:prefix) { should eq 'namespace|u.3wepSyz' }
      its(:meta) { should eq 'namespace|u.3wepSyz.m' }
      its(:data) { should eq 'namespace|u.3wepSyz.d' }
    end

    context 'without a namespace' do
      let(:namespace) { nil }
      subject { described_class.new(user_id) }
      its(:short_id) { should eq '3wepSyz' }
      its(:prefix) { should eq 'u.3wepSyz' }
      its(:meta) { should eq 'u.3wepSyz.m' }
      its(:data) { should eq 'u.3wepSyz.d' }
      its(:to_s) { should match /3wepSyz/ }
    end
  end
end
