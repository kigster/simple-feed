#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../../../lib', __FILE__)

# Please set @feed in the enclosing context

raise ArgumentError, 'No @feed defined in the enclosing example' unless defined?(@feed)

require 'simplefeed'
require 'uuid'

srand(Time.now.to_i % 100003)

@number_of_users = ARGV[0] ? ARGV[0].to_i : 2
@users = @number_of_users.times.map do |n|
  n % 2 == 0 ? UUID.generate : rand(100003)
end

@activity        = @feed.activity(@users)
@uid             = @users.first

include SimpleFeed::DSL

class Object
  def _v
    self.to_s.bold.red
  end
end

def p(*args)
  printf "%40s -> %s\n", args[0].strip.blue.bold, args[1].bold.red
end

with_activity(@activity) do
  header "#{@activity.feed.provider_type} provider example".upcase,
         "Starting with a blank feed, no items",
         align: :center

  wipe

  store('value one')        { p 'storing new value', 'value one' }
  store('value two')        { p 'storing new value', 'value two' }
  store('value three')      { p 'storing new value', 'value three' }

  total_count               { |r| p 'total_count is now', "#{r[@uid]._v}" }
  unread_count              { |r| p 'unread_count is now', "#{r[@uid]._v}" }

  header 'activity.paginate(page: 1, per_page: 2)'
  paginate(page: 1, per_page: 2) { |r| puts r[@uid].map(&:to_color_s) }

  header 'activity.paginate(page: 2, per_page: 2, reset_last_read: true)'
  paginate(page: 2, per_page: 2, reset_last_read: true) { |r| puts r[@uid].map(&:to_color_s) }

  total_count           { |r| p 'total_count ', "#{r[@uid]._v}" }
  unread_count              { |r| p 'unread_count ', "#{r[@uid]._v}" }

  store('value four')   { p 'storing', 'value four' }

  color_dump

  header 'deleting'

  delete('value three')     { p 'deleting', 'value three' }

  total_count               { |r| p 'total_count ', "#{r[@uid]._v}" }
  unread_count              { |r| p 'unread_count ', "#{r[@uid]._v}" }

  hr

  delete('value four')      { p 'deleting', 'value four' }
  total_count               { |r| p 'total_count ', "#{r[@uid]._v}" }
  unread_count              { |r| p 'unread_count ', "#{r[@uid]._v}" }

  puts
end

notes = [
  'Thanks for trying SimpleFeed!', 'For any questions, reach out to',
  'kigster@gmail.com',
]

unless ENV['REDIS_DEBUG']
  notes << [
  '———',
    'To see REDIS commands, set REDIS_DEBUG environment variable to true,',
    'and re-run the example.'
  ]
end

header notes.flatten,
       align: :center
