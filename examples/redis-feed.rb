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
  f.provider = SimpleFeed.provider(:redis, redis: -> { Redis.new }, pool_size: 2)
end

# You can pass number of users on the command line 
@number_of_users = ARGV[0] ? ARGV[0].to_i :  1
@users           = Array.new(@number_of_users) { rand(200_000_000...800_000_000) }

@ua = @feed.for(@users)

Formatter.header

Formatter.print('___________________________________________________________________________', user_id: nil, pp: true) do

  Formatter.print('#wipe entire feed for %user%', user_id: @users)             { @ua.wipe }
  
  Formatter.print("#store value 'hello' for %user%", user_id: @users)          { @ua.store(value: 'hello', at: Time.now) }
  Formatter.print("#store value 'goodbye' for %user%", user_id: @users)        { @ua.store(value: 'goodbye', at: Time.now) }
  Formatter.print("#store value 'goodbye' again %user%", user_id: @users)      { @ua.store(value: 'goodbye') }
  
  Formatter.print('#total_count for %user% is now', user_id: @users)           { @ua.total_count }
  Formatter.print('#unread_count for %user% is now', user_id: @users)          { @ua.unread_count }
  Formatter.print('#last_read for %user% is now', user_id: @users)             { @ua.last_read }
  
  Formatter.print('#paginate event page for %user%', pp: true, user_id: @users){ @ua.paginate(page: 1, per_page: 5) }
  
  Formatter.print('#unread_count for %user% is now', user_id: @users)          { @ua.unread_count }
  Formatter.print('#last_read for %user% is now', user_id: @users)             { @ua.last_read }
  
  Formatter.print("#remove value 'goodbye' for %user%", user_id: @users)       { @ua.remove(value: 'goodbye') }
  
  Formatter.print('#total_count for %user% is now', user_id: @users)           { @ua.total_count }
  Formatter.print('#unread_count for %user% is now', user_id: @users)          { @ua.unread_count }
  
  Formatter.print('#paginate event page for %user%', pp: true, user_id: @users){ @ua.paginate(page: 1, per_page: 5) }
  Formatter.print('#wipe entire feed for %user%', user_id: @users)             { @ua.wipe }
  Formatter.print('#paginate event page for %user%', pp: true, user_id: @users){ @ua.paginate(page: 1, per_page: 5) }
  
  :TotalTime 
  
end

