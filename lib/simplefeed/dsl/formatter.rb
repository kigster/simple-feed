require 'simplefeed/dsl'
require 'simplefeed/activity/single_user'
require 'simplefeed/activity/multi_user'
module SimpleFeed
  module DSL
    # This module exports method #color_dump which receives an activity and
    # then prints out a report about the activity, including the event
    # data found for a given user.
    module Formatter
      include SimpleFeed::DSL

      attr_accessor :activity, :feed

      def color_dump(this_activity = activity)
        this_activity = if this_activity.is_a?(SimpleFeed::Activity::SingleUser)
                      this_activity.feed.activity([this_activity.user_id])
                    else
                      this_activity
                    end
        _puts

        header do
          field('Feed Name', feed.name, "\n")
          field('Provider', feed.provider.provider.class, "\n")
          field('Max Size', feed.max_size, "\n")
        end

        with_activity(this_activity) do
          this_activity.each do |user_id|
            this_last_event_at = nil
            this_last_read     = (last_read[user_id] || 0.0).to_f

            [['User ID', user_id, "\n"],
             ['Activities', sprintf('%d total, %d unread', total_count[user_id], unread_count[user_id]), "\n"],
             ['Last Read', this_last_read ? Time.at(this_last_read) : 'N/A'],
            ].each do |field, value, *args|
              field(field, value, *args)
            end

            _puts; hr '¨'

            this_events       = fetch[user_id]
            this_events_count = this_events.size
            this_events.each_with_index do |_event, _index|

              if this_last_event_at.nil? && _event.at < this_last_read
                print_last_read_separator(this_last_read)
              elsif this_last_event_at && this_last_read < this_last_event_at && this_last_read > _event.at
                print_last_read_separator(this_last_read)
              end

              this_last_event_at = _event.at # float
              _print "[%2d] %16s %s\n", _index, _event.time.strftime(TIME_FORMAT).blue.bold, _event.value
              if _index == this_events_count - 1 && this_last_read < _event.at
                print_last_read_separator(this_last_read)
              end
            end
          end
        end
      end

      def print_last_read_separator(lr)
        _print ">>>> %16s <<<< last read\n", Time.at(lr).strftime(TIME_FORMAT).red.bold
      end
    end

    @print_method = :printf

    class << self
      attr_accessor :print_method
    end

    def _print(*args, **opts, &block)
      send(SimpleFeed::DSL.print_method, *args, **opts, &block)
    end

    def _puts(*args)
      send(SimpleFeed::DSL.print_method, "\n" + args.join)
    end

    def field_label(text)
      sprintf ' %20s ', text
    end

    TIME_FORMAT = '%Y-%m-%d %H:%M:%S.%L'

    def field_value(value)
      case value
        when Numeric
          sprintf '%-20d', value
        when Time
          sprintf '%-30s', value.strftime(TIME_FORMAT)
        else
          sprintf '%-20s', value.to_s
      end
    end

    def field(label, value, sep = '')
      _print field_label(label).italic + field_value(value).cyan.bold + sep
    end

    def hr(char = '—')
      _print(_hr(char).magenta)
    end

    def _hr(char = '—')
      char * 75 + "\n"
    end

    def header(message = nil)
      _print(_hr.green.bold)
      block_given? ? yield : _print(message.green.italic + "\n")
      _print(_hr.green.bold)
    end
  end
end
