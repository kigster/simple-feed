# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SimpleFeed::Providers::Key do
  let(:consumer) { USER_IDS_TO_TEST.first }
  let(:namespace) { nil }

  let(:meta_key_transformer) { nil }
  let(:data_key_transformer) { nil }

  subject(:key) {
    described_class.new(consumer,
                        namespace:            namespace,
                        data_key_transformer: data_key_transformer,
                        meta_key_transformer: meta_key_transformer)
  }

  context 'initialization' do
    context 'with a namespace' do
      let(:namespace) { :namaste }
      its(:meta) { should eq 'namaste|u.3wepSyz.m' }
      its(:data) { should eq 'namaste|u.3wepSyz.d' }
      its(:keys) { should eq %w(namaste|u.3wepSyz.m namaste|u.3wepSyz.d).sort }
    end

    context 'without a namespace' do
      let(:namespace) { nil }
      its(:meta) { should eq 'u.3wepSyz.m' }
      its(:data) { should eq 'u.3wepSyz.d' }
      its(:to_s) { should include "data_id=\"3wepSyz\" meta_id=\"3wepSyz\" namespace=\"\"" }
      its(:inspect) { should =~ /3wepSyz/ }
      its(:keys) { should eq %w(u.3wepSyz.m u.3wepSyz.d).sort }
    end
  end

  context 'with custom transformers' do
    let(:uuid) { 'c387e6b0-8091-0138-3c8f-2cde48001122' }
    let(:consumer_class) { Struct.new(:id, :zipcode) }
    let(:consumer) { consumer_class.new(uuid, '94107') }
    let(:namespace) { :poo }

    let(:meta_key_transformer) do
      ->(consumer) do
        consumer.id
      end
    end

    let(:data_key_transformer) do
      ->(consumer) do
        consumer.zipcode
      end
    end

    context '#key_params' do
      subject { key.send(:key_params) }

      its(:meta_id) { should eq described_class.rot13(consumer.id) }
      its(:data_id) { should eq ::Base62.encode(consumer.zipcode.to_i) }
    end

    its(:meta_id) { should eq consumer.id }
    its(:data_id) { should eq consumer.zipcode }

    its(:data) { should eq "poo|u.otR.d" }
    its(:meta) { should eq "poo|u.p387r6o0-8091-0138-3p8s-2pqr48001122.m" }
    its(:keys) { should eq %w[poo|u.otR.d poo|u.p387r6o0-8091-0138-3p8s-2pqr48001122.m] }
  end
end
