require 'simplefeed/dsl'

module SimpleFeed
  module DSL
    module Formatter

      include SimpleFeed::DSL

      attr_accessor :activity, :feed

      def initialize(activity)
        self.activity = activity
        self.feed     = activity.feed
      end

      def color_dump
        puts

        header do
          field('Feed Name', feed.name, "\n")
          field('Provider', feed.provider.provider.class, "\n")
          field('Max Size', feed.max_size, "\n")
        end

        with_activity(activity) do

          lr        = last_read
          last_time = nil

          [['User ID', activity.user_id, "\n"],
           ['Activities', sprintf('%d total, %d unread', total_count, unread_count), "\n"],
           ['Last Read', lr ? Time.at(lr) : 'N/A'],
          ].each do |field, value, *args|
            field(field, value, *args)
          end
          puts ; hr '¨'

          lr = Time.at(lr || 0)

          fetch.each_with_index do |e, i|
            if last_time && last_time > lr && e.time <= lr
              printf ">>>> %16s <<<< last read\n", lr.strftime(TIME_FORMAT).red.bold
            end
            last_time = e.time
            printf "[%2d] %16s %s\n", i, e.time.strftime(TIME_FORMAT).blue.bold, e.value
          end
        end
      end
    end

    def header
      hr
      yield
      hr
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
      printf field_label(label).italic + field_value(value).cyan.bold + sep
    end

    def hr(char = '—')
      print (char * 100 + "\n").magenta
    end
  end
end
