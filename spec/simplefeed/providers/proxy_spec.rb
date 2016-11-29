require 'spec_helper'

RSpec.shared_examples :validate_provider do
  subject(:provider) { proxy.provider }
  context 'instantiation' do
    it('should be of a correct class') { is_expected.to be_kind_of(SimpleFeed::MockProvider) }
    it 'should correctly set all array args' do
      expect(provider.host).to eq(args.first)
      expect(provider.port).to eq(args.last)
    end
    it 'should correctly set all hash args' do
      expect(provider.db).to eq opts[:db]
      expect(provider.namespace).to eq opts[:namespace]
    end
  end

  context 'existing method forwarding' do
    it 'should correctly forward to the provider all unknown methods' do
      expect(proxy.name).to eq(SimpleFeed::MockProvider::NAME)
    end
  end
  context 'unknown method forwarding' do
    it 'should correctly invoke #method_missing on super' do
      expect { proxy.some_long_method_name }.to raise_error(NameError)
    end
  end

end

RSpec.describe SimpleFeed::Providers::Proxy do
  context 'direct instantiation' do
    let(:klass) { 'SimpleFeed::MockProvider' }
    let(:args) { %w(127.0.0.1 6379) }
    let(:opts) { { db: 1, namespace: :mock } }
    let(:proxy) { SimpleFeed::Providers::Proxy.new(klass, *args, **opts) }

    include_examples :validate_provider
  end

  context 'using fixtures' do
    let(:props) { SimpleFeed::Fixtures.mock_provider_props }
    let(:klass) { props[:klass] }
    let(:args) { props[:args] }
    let(:opts) { props[:opts] }

    context 'directly instantiating' do
      let(:proxy) { SimpleFeed::Providers::Proxy.new(klass, *args, **opts) }

      it 'should correctly read the fixtures' do
        expect(klass).to eq('SimpleFeed::MockProvider')
        expect(args).to eq(%w(127.0.0.1 6379))
        expect(opts).to eq({ db: 1, namespace: :mock })
      end

      it 'should correctly instantiate Proxy based on fixture' do
        expect(proxy.provider).to be_a_kind_of(SimpleFeed::MockProvider)
      end

      include_examples :validate_provider
    end

    context 'self.from' do
      let(:proxy) { SimpleFeed::Providers::Proxy.from(props) }

      include_examples :validate_provider

    end
  end
end
