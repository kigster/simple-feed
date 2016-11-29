require 'spec_helper'
require 'colored2'

module SimpleFeed
  module Testing
    
    @debug = true
    def self.debug?; @debug; end
    
    SimpleFeed::Providers.define_provider_methods(self) do |instance, method, *args, **opts, &block|
      activity = args[0]
      event    = args[1]
      
      opts.merge!(event: event) if event
      
      printf " #{instance.feed.name.to_s.blue}.#{sprintf("%-16s", method.to_s).magenta}(#{opts.to_s.gsub(/[\{\}]/, '').blue}) \n\t\t\t" if self.debug?
      
      response = ua.send(method, **opts)
      
      puts '———> ' + response.inspect.green if self.debug?
      yield(response) if block_given?
      response
    end

    def check_counts(user_id, total, unread = total)
      #puts 'total: ' + total_count(ua[user_id]).inspect
      expect(total_count(ua[user_id])).to eq(total)
      #puts 'unread: ' + unread_count(ua[user_id]).inspect
      # expect(unread_count(ua[user_id])).to eq(unread)
    end

    def users(feed, user_ids = [])
      feed.for(user_ids).wipe
      yield(feed.for(user_ids))
    end
  end

# Requires the following variables set:
#  * provider_opts

  shared_examples 'a provider' do
    include Shortcuts

    subject(:feed) {
      SimpleFeed.define(:tested_feed) do |f|
        f.max_size = 5
        f.provider = described_class.new(provider_opts)
      end
    }

    before { feed }

    include_context :event_matrix

    let(:user_id) { 99119911991199 }
    # UserActivity (or UsersActivity)
    let(:ua) { ->(user_id) { SimpleFeed.tested_feed.for(user_id) } }

    context '#store' do

      context 'storing and removing events' do
        it('returns valid responses back from each operation') do
          users [user_id] do |id|
            wipe ua[id]
            store ua[id], event { |result| expect(result[id]).to eq(true) }
            store ua[id], another_event { |result| expect(result[id]).to eq(true) }
            all ua[id] { |result| expect(result[id].size).to eq(2) }
            total_count ua[id] { |result| expect(result[id]).to eq(2) }
            store ua[id], event { |result| expect(result[id]).to eq(false) }
            remove ua[id], event { |result| expect(result[id]).to eq(true) }
            remove ua[id], event { |result| expect(result[id]).to eq(false) }
          end
        end
      end

      context 'adding two events' do
        before do
          users [user_id] do |id|
            store ua[id], events[1]
            store ua[id], events[0]
            total_count ua[id] { |result| expect(result[id]).to eq(2) }
          end
        end

        xit('has two events') { check_counts(user_id, 2, 2) }

        context '#remove' do
          context 'one event' do
            it('has one event left') do
              remove ua[user_id], event { |result| expect(result).to_not be_nil }
              check_counts(user_id, 1, 1)
            end
          end

          context 'non-existing event' do
            it 'has one event left still' do
              all ua[user_id] { |result| expect(result[user_id].size).to eq(2) }
              remove ua[user_id], events[1] { |result| expect(result[user_id]).to eq(true) }
              remove ua[user_id], events[1] { |result| expect(result[user_id]).to eq(false) }
              check_counts(user_id, 1, 1)
            end
          end
        end

        context '#paginate' do
          let(:ts) { Time.now }
          it 'resets last read, and returns the first event as page 1' do
            reset_last_read(ua[user_id], at: ts) { |result| expect(result[user_id]).to eq(ts) }
            paginate(ua[user_id], page: 1, per_page: 1) { |result| expect(result[user_id]).to_not be_empty }
            last_read(ua[user_id]) { |result| expect(result[user_id]).not_to eq(ts) }
          end
        end
      end
    end
  end
