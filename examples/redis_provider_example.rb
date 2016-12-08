#!/usr/bin/env ruby

# This is an executable example of working with a Redis feed, and storing
# events for various users.
# 
# DEPENDENCIES: 
#   gem install colored2
#   gem install awesome_print
#
# RUNNING
#   ruby examples/redis-feed.rb [ number_of_users ] 
#
# TO SEE ALL REDIS COMMANDS:
#   export REDIS_DEBUG=1
#   ruby examples/redis-feed.rb

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'simplefeed'

@feed = SimpleFeed.define(:news) do |f|
  f.provider = SimpleFeed.provider(:redis,
                                   redis: -> { Redis.new },
                                   pool_size: 10,
                                   batch_size: 10)
end

require_relative 'shared/provider_example'
