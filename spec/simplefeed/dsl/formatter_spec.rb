require 'spec_helper'
require 'simplefeed/dsl/formatter'
class TestDSL;
end

describe SimpleFeed::DSL::Formatter do
  let(:feed) { SimpleFeed::Fixtures.follow_feed }
  let(:user_ids) { [1, 2, 3, 4, 5] }
  let(:activity) { feed.activity(user_ids) }

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
                         event('Another Important Story', ts2.to_f)].sort }

    let(:user_last_read) { {
      1 => ts1 + 5.5, # between the two
      2 => ts1 + 1.1, # between the two
      3 => ts3 - 1.5,
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
          expect_any_instance_of(SimpleFeed::DSL::Activities).to receive(:print_last_read_separator).exactly(5).times
          expect_any_instance_of(SimpleFeed::DSL::Activities).to receive(:fetch).exactly(5).times.and_return(fetch_response[user_events])
          expect_any_instance_of(SimpleFeed::DSL::Activities).to receive(:last_read).exactly(5).times.and_return(user_last_read)
        end

        color_dump(activity)

        context.instance_eval do
          expect(SimpleFeed::DSL.main_output).to match /User ID/
          expect(SimpleFeed::DSL.main_output).to match /#{user_events.first.value}/
          expect(SimpleFeed::DSL.main_output).to match /#{user_events.last.value}/
        end
      end
    end
  end
end
