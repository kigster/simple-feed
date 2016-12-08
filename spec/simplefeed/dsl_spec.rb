require 'spec_helper'

class TestDSL;
end

describe SimpleFeed::DSL do
  context 'included in a Test Class' do
    subject(:test_module) { TestDSL }
    before { test_module.include described_class }
    its(:new) { should respond_to :with_activity }
  end

  context 'included in the RSpec context' do
    include SimpleFeed::DSL

    let(:feed) { SimpleFeed::Fixtures.follow_feed }
    let(:user_ids) { [1, 2, 3, 4, 5] }
    let(:activity) { feed.activity(user_ids) }

    it(' should have feed defined') { expect(activity.feed).to eq feed }

    let(:with_activity_block) { ->(&block) { with_activity(activity, context: self, &block) } }
    let(:user_responses_should_eq) do
      ->(value) do
        ->(response) { response.values.each { |v| expect(v).to eq value } }
      end
    end

    it 'should be able to store and fetch counts' do
      with_activity_block.call do
        total_count result: 0, &context.user_responses_should_eq[0]
        store value: 'hello', result: 'hello', &context.user_responses_should_eq['hello']
        unread_count result: 0, &context.user_responses_should_eq[0]
      end
    end
  end

end
