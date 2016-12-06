require 'simplefeed/dsl'

module SimpleFeed
  module DSL
    module Formatter

      include SimpleFeed::DSL

      attr_accessor :activity, :feed

      def color_dump
        local_puts

        header do
          field('Feed Name', feed.name, "\n")
          field('Provider', feed.provider.provider.class, "\n")
          field('Max Size', feed.max_size, "\n")
        end

        with_activity(activity) do
          last_time = nil

          activity.each do |user_id|
            lr = last_read[user_id]
            [['User ID', user_id, "\n"],
             ['Activities', sprintf('%d total, %d unread', total_count[user_id], unread_count[user_id]), "\n"],
             ['Last Read', lr ? Time.at(lr) : 'N/A'],
            ].each do |field, value, *args|
              field(field, value, *args)
            end

            local_puts; hr '¨'

            lr = Time.at(lr || 0)

            fetch[user_id].each_with_index do |e, i|
              if last_time && last_time > lr && e.time <= lr
                print_last_read_separator(lr)
              end
              last_time = e.time
              local_print "[%2d] %16s %s\n", i, e.time.strftime(TIME_FORMAT).blue.bold, e.value
            end
          end
        end
      end

      def print_last_read_separator(lr)
        local_print ">>>> %16s <<<< last read\n", lr.strftime(TIME_FORMAT).red.bold
      end
    end

    @print_method = :printf

    class << self
      attr_accessor :print_method
    end

    def local_print(*args, **opts, &block)
      send(SimpleFeed::DSL.print_method, *args, **opts, &block)
    end

    def local_puts(*args)
      send(SimpleFeed::DSL.print_method, "\n" + args.join)
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
      local_print field_label(label).italic + field_value(value).cyan.bold + sep
    end

    def hr(char = '—')
      local_print (char * 100 + "\n").magenta
    end
  end
end
