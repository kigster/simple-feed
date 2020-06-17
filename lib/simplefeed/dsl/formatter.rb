# frozen_string_literal: true

require 'tty-box'
require 'tty-screen'
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

        feed_header(feed) do
          [
            field('Feed Name', feed.name, "\n"),
            field('Provider', feed.provider.provider.class, "\n"),
            field('Max Size', feed.max_size, "\n")
          ]
        end

        with_activity(this_activity) do
          this_activity.each_with_index do |user_id, index|
            this_last_event_at = nil
            this_last_read     = (last_read[user_id] || 0.0).to_f

            fields = []
            [['User ID', user_id, "\n"],
             ['Activities', sprintf('%d total, %d unread', total_count[user_id], unread_count[user_id]), "\n"],
             ['Last Read', this_last_read ? Time.at(this_last_read) : 'N/A'],].each do |field, value, *args|
              fields << field(field, value, *args)
            end

            header(title: { top_center: " « User Activity #{index + 1} » " }) { fields.map(&:green) }

            this_events       = fetch[user_id]
            this_events_count = this_events.size
            this_events.each_with_index do |_event, _index|
              if this_last_event_at.nil? && _event.at < this_last_read
                print_last_read_separator(this_last_read)
              elsif this_last_event_at && this_last_read < this_last_event_at && this_last_read > _event.at
                print_last_read_separator(this_last_read)
              end

              this_last_event_at = _event.at # float
              output "[%2d] %16s %s\n", _index, _event.time.strftime(TIME_FORMAT).blue.bold, _event.value
              if _index == this_events_count - 1 && this_last_read < _event.at
                print_last_read_separator(this_last_read)
              end
            end
          end
        end
      end

      def print_last_read_separator(lr)
        output ">>>> %16s <<<< last read\n", Time.at(lr).strftime(TIME_FORMAT).red.bold
      end
    end

    # This allows redirecting output in tests.
    @print_method = :printf

    class << self
      attr_accessor :print_method
    end

    def output(*args, **opts, &block)
      send(SimpleFeed::DSL.print_method, *args, **opts, &block)
    end

    def _puts(*args)
      send(SimpleFeed::DSL.print_method, "\n" + args.join)
    end

    def field_label(text)
      sprintf ' %20s ', text
    end

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

    def field(label, value, _sep = '')
      field_label(label) + ' -> ' + field_value(value)
    end

    def hr
      output hr_string.magenta
    end

    def hr_string
      '―' * width + "\n"
    end

    def width
      @width ||= TTY::Screen.width - 5
    end

    def feed_header(feed, &block)
      header title:  { top_left: " « #{feed.name.capitalize} Feed » " },
             border: :thick,
             style:  {
               fg:     :bright_red,
               border: { fg: :white }
             }, &block
    end

    def header(*args, **opts)
      message = args.join("\n")
      msg = block_given? ? (yield || message) : message + "\n"
      box = TTY::Box.frame(box_config(**opts)) { Array(msg).join("\n") }
      output "\n#{box}"
    end

    private

    def box_config(**opts)
      {
        width:   width,
        align:   :left,
        padding: [0, 3],
        style:   {
          fg:     :bright_yellow,
          border: {
            fg: :bright_magenta,
          }
        }
      }.merge(opts)
    end
  end
end
