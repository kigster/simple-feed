require 'spec_helper'

RSpec.describe SimpleFeed::Providers::Serialization::Key do
  let(:user_id) { 199929993999 }
  let(:config) { {} }
  subject { described_class.new(user_id, namespace, ) }

  context 'initialization' do
    let(:namespace) { :namespace }
    context 'with a namespace' do
      its(:base62_user_id) { should eq '3wepSyz' }
      its(:meta) { should eq 'namespace|u.3wepSyz.m' }
      its(:data) { should eq 'namespace|u.3wepSyz.d' }
      its(:keys) { should eq %w(namespace|u.3wepSyz.m namespace|u.3wepSyz.d).sort }
    end

    context 'without a namespace' do
      let(:namespace) { nil }
      subject { described_class.new(user_id, nil) }
      its(:base62_user_id) { should eq '3wepSyz' }
      its(:meta) { should eq 'u.3wepSyz.m' }
      its(:data) { should eq 'u.3wepSyz.d' }
      its(:to_s) { should include 'base62_user_id=>"3wepSyz"' }
      its(:inspect) { should =~ /3wepSyz/ }
      its(:keys) { should eq %w(u.3wepSyz.m u.3wepSyz.d).sort }
    end
  end

  context 'shared data, separate meta' do
    let(:namespace) { nil }
    subject { described_class.new(user_id, nil) }
    its(:base62_user_id) { should eq '3wepSyz' }
    its(:meta) { should eq 'u.3wepSyz.m' }
    its(:data) { should eq 'u.3wepSyz.d' }
    its(:to_s) { should include 'base62_user_id=>"3wepSyz"' }
    its(:inspect) { should =~ /3wepSyz/ }
    its(:keys) { should eq %w(u.3wepSyz.m u.3wepSyz.d).sort }


  end
end
