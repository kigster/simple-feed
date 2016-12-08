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

@feed = SimpleFeed.define(:news) do |f|
  f.provider = SimpleFeed.provider(:hash)
  f.max_size = 1000
end

require_relative 'shared/provider_example'

