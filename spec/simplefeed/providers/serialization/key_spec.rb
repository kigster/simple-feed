require 'spec_helper'

RSpec.describe SimpleFeed::Providers::Key do
  let(:user_id) { 199929993999 }
  let(:namespace) { nil }
  let(:key_template) { SimpleFeed::Key::Template.new(namespace) }

  subject { described_class.new(user_id, key_template) }

  context 'initialization' do
    context 'with a namespace' do
      let(:namespace) { :namaste }
      its(:base62_user_id) { should eq '3wepSyz' }
      its(:meta) { should eq 'namaste|u.3wepSyz.m' }
      its(:data) { should eq 'namaste|u.3wepSyz.d' }
      its(:keys) { should eq %w(namaste|u.3wepSyz.m namaste|u.3wepSyz.d).sort }
    end

    context 'without a namespace' do
      let(:namespace) { nil }
      its(:base62_user_id) { should eq '3wepSyz' }
      its(:meta) { should eq 'u.3wepSyz.m' }
      its(:data) { should eq 'u.3wepSyz.d' }
      its(:to_s) { should include 'base62_user_id=>"3wepSyz"' }
      its(:inspect) { should =~ /3wepSyz/ }
      its(:keys) { should eq %w(u.3wepSyz.m u.3wepSyz.d).sort }
    end
  end

  context 'custom key definition' do
    let(:namespace) { :poo }
    let(:text_template) { SimpleFeed::Key::TextTemplate.new('{{ namespace }}user:{{ base62_user_id }}/{{ key_marker }}') }
    let(:key_template) { SimpleFeed::Key::Template.new(namespace,
                                                       [ SimpleFeed::Key::Type.new(:beta, 'B'),
                                                         SimpleFeed::Key::Type.new(:gamma, 'G') ],
                                                       text_template)
    }
    subject { described_class.new(user_id, key_template) }

    its(:beta) { should eq 'poo|user:3wepSyz/B' }
    its(:gamma) { should eq 'poo|user:3wepSyz/G' }
    its(:to_s) { should include 'base62_user_id=>"3wepSyz"' }
    its(:inspect) { should =~ /3wepSyz/ }
    its(:keys) { should eq %w(poo|user:3wepSyz/B poo|user:3wepSyz/G).sort }
    its(:key_names) { should eq %w(beta gamma).sort }
  end
end
