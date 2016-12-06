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

    context 'formatter' do

      let(:main_output) { '' }

      module SimpleFeed
        module DSL
          @main_output = ''
          class << self
            attr_accessor :main_output
          end

          def collect_in_rspec(*args, **opts, &block)
            SimpleFeed::DSL.main_output << sprintf(*args, **opts, &block)
          end
        end
      end

      let(:fetch_response) do
        ->(user_result) {
          user_ids.inject({}) do |hash, id|
            hash[id] = user_result
            hash
          end
        }
      end

      context '#color_dump' do
        let(:ts1) { Time.now - 20 }
        let(:ts2) { Time.now - 10 }
        let(:ts3) { Time.now }

        let(:user_events) { [event('First Story', ts1.to_f),
                             event('Another Important Story', ts2.to_f)] }

        let(:user_last_read) { {
          1 => ts1 + 5.5, # between the two
          2 => ts1 + 1.1, # between the two
          3 => ts3 - 1.5 ,
          4 => ts2 - 100000.4,
          5 => ts2 - 6.2 } # between the two
        }

        it 'should define responses as a hash' do
          expect(fetch_response[user_events][1]).to be_kind_of Array
          expect(fetch_response[user_events][1].size).to be 2
          expect(fetch_response[user_events].size).to be 5
        end

        before do
          SimpleFeed::DSL.print_method = :collect_in_rspec
        end

        it 'should be able print the feed contents' do
          with_activity(activity, context: self) do
            context.instance_eval do
              expect_any_instance_of(SimpleFeed::DSL::Activities).to receive(:print_last_read_separator).exactly(2).times
              expect_any_instance_of(SimpleFeed::DSL::Activities).to receive(:fetch).exactly(5).times.and_return(fetch_response[user_events])
              expect_any_instance_of(SimpleFeed::DSL::Activities).to receive(:last_read).exactly(5).times.and_return(user_last_read)
            end

            color_dump

            context.instance_eval do
              expect(SimpleFeed::DSL.main_output).to match /User ID/
              expect(SimpleFeed::DSL.main_output).to match /#{user_events.first.value}/
              expect(SimpleFeed::DSL.main_output).to match /#{user_events.last.value}/
            end
          end
        end
      end
    end
  end
end
