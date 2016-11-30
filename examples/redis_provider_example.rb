#!/usr/bin/env ruby

# This is an executable example of working with a Redis feed, and storing
# events for various users.
# 
# DEPENDENCIES: 
#  gem install colored2
#  gem install awesome_print
#
# RUNNING
#  ruby redis-feed.rb
#

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'simplefeed'
require_relative 'response_formatter'

@feed = SimpleFeed.define(:news) do |f|
  f.provider = SimpleFeed.provider(:redis,
                                   redis: -> { Redis.new },
                                   pool_size: 10,
                                   batch_size: 10)
end

# You can pass number of users on the command line 
@number_of_users = ARGV[0] ? ARGV[0].to_i : 1
@users           = Array.new(@number_of_users) { rand(200_000_000...800_000_000) }
@ua              = @feed.users_activity(@users)

Formatter.header
Formatter.with_timing(ua: @ua) do

  p('#wipe entire feed for %user%')             { ua.wipe }
  p("#store value 'hello' for %user%")          { ua.store(value: 'hello', at: Time.now) }
  p("#store value 'goodbye' for %user%")        { ua.store(value: 'goodbye', at: Time.now) }
  p("#store value 'goodbye' again %user%")      { ua.store(value: 'goodbye') }

  p('#total_count for %user% is now')           { ua.total_count }
  p('#unread_count for %user% is now')          { ua.unread_count }
  p('#last_read for %user% is now')             { ua.last_read }

  p('#paginate event page for %user%', pp: 1)   { ua.paginate(page: 1, per_page: 5) }
  p('#unread_count for %user% is now')          { ua.unread_count }
  p('#last_read for %user% is now')             { ua.last_read }

  p("#remove value 'goodbye' for %user%")       { ua.remove(value: 'goodbye') }

  p('#total_count for %user% is now')           { ua.total_count }
  p('#unread_count for %user% is now')          { ua.unread_count }

  p('#paginate event page for %user%', pp: 1)   { ua.paginate(page: 1, per_page: 5) }
  p('#wipe entire feed for %user%')             { ua.wipe }
  p('#paginate event page for %user%', pp: 1)   { ua.paginate(page: 1, per_page: 5) }

end

