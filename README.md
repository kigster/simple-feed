## SimpleFeed — Scalable, easy to use activity feed implementation.

[![Gem Version](https://badge.fury.io/rb/simple-feed.svg)](https://badge.fury.io/rb/simple-feed)
[![MIT licensed](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/kigster/simple-feed/master/LICENSE.txt)
[![Build Status](https://travis-ci.org/kigster/simple-feed.svg?branch=master)](https://travis-ci.org/kigster/simple-feed)
[![Code Climate](https://codeclimate.com/repos/58339a5b3d9faa74ac006b36/badges/8b899f6df4fc1ed93759/gpa.svg)](https://codeclimate.com/repos/58339a5b3d9faa74ac006b36/feed)
[![Test Coverage](https://codeclimate.com/repos/58339a5b3d9faa74ac006b36/badges/8b899f6df4fc1ed93759/coverage.svg)](https://codeclimate.com/repos/58339a5b3d9faa74ac006b36/coverage)
[![Issue Count](https://codeclimate.com/repos/58339a5b3d9faa74ac006b36/badges/8b899f6df4fc1ed93759/issue_count.svg)](https://codeclimate.com/repos/58339a5b3d9faa74ac006b36/feed)

This is a ruby implementation of a fast simple feed commonly used in a typical social network-like applications. The implementation is optimized for **read-time performance** and high concurrency (lots of users). A default Redis-based provider implementation is provided, with the API supporting new providers very easily. 

<div style="border: 2px solid #222; padding: 10px; background: #f5f5f5; font-family: 'HelveticaNeue-CondensedBold'; font-size: 14pt;">
<ol>
    <li>Please note that this project is under <em>active development</em>, and is not yet completed.<br/></li>
    <li>We thank <em><a href="http://simbi.com">Simbi, Inc.</a></em> for sponsoring the development of this open source library.</li>
</div>

### What's an Activity Feed?

Here is an example of a text-based simple feed that is very common today on social networking sites.

[![Example](https://raw.githubusercontent.com/kigster/simple-feed/master/man/sf-example.png)](https://raw.githubusercontent.com/kigster/simple-feed/master/man/sf-example.png)

The _stories_ in the feed depend entirely on the application using this
library, therefore to integrate with SimpleFeed requires implementing
several _glue points_ in your code.

### Overview
 
 The feed library aims to address the following goals:

* To define a minimalistic API for a typical event-based simple feed,
  without tying it to any concrete provider implementation
* To make it easy to implement and plug in a new type of provider,
  eg.using Couchbase or MongoDB
* To provide a scalable default provider implementation using Redis, which can support millions of users via sharding 
* To support multiple simple feeds within the same application, but used for different purposes, eg. simple feed of my followers, versus simple feed of my own actions.

### Usage

First you need to configure the Feed with a valid provider
implementation and a name. 

#### Configuration

Below we configure a feed called `:followed_activity`, which presumably
will be populated with the events coming from the followers.

```ruby
require 'simplefeed'
require 'simplefeed/providers/redis'

SimpleFeed.define(:followed_activity) do |f|
  f.provider = SimpleFeed::Providers::Redis.new(
    redis: -> { ::Redis.new(host: '127.0.0.1') },
  )
  f.max_size = 1000 # how many items can be in the feed
  f.per_page = 20 # default page size
end

SimpleFeed.feed(:notifications) do |f|
  f.provider = SimpleFeed::Providers::Redis.new(
    redis: ::ConnectionPool.new(size: 5, timeout: 5) do
      ::Redis.new(host: '192.168.10.10', port: 9000)
    end
  )
  f.per_page = 50
end

```

After the feed is defined, the gem creates a similarly named method
under the `SimpleFeed` namespace to access the feed. For example, given
a name such as `:friends_news` the following are all valid ways of
accessing the feed:

 * `SimpleFeed.friends_news`
 * `SimpleFeed.get(:friends_news)`

You can also get a full list of currently defined feeds with `SimpleFeed.feed_names` method.

#### Publishing Data to the Feed

When we publish events to the feeds, we typically (although not always) do it for many feeds at the same time. This is why the write operations expect a list of users, or an enumeration, or a block yielding batches of the users:

```ruby
require 'simplefeed'
user_ids = current_user.followed.map(&:id) # => [ 123, 545, ... ]
user_ids.each do |user_id|
  SimpleFeed.followed_activity.store(user_id, 'Jon followed Igbis', Time.now)
end
```

#### Reading the Feed

```ruby
require 'simplefeed'
  
user_feed = SimpleFeed.followed_activity.for(user_id)
user_feed.unread_count
#=> 12
user_feed.paginate(page: 1, reset_last_read: false) 
# => [ 
# <SimpleFeed::Event#0x2134afa value='Jon followed Igbis' at='2016-11-20 23:32:56 -0800'>,
# <SimpleFeed::Event#0xf98f234 value='George liked Jons post' at='2016-12-10 21:32:56 -0800'>
# ....
# ]
# now, let's force-reset the last read timestamp
user_feed.reset_last_read # defaults to Time.now
#=> 0
user_feed.unread_count
#=> 0
```

### Installation

Add this line to your application's Gemfile:

```ruby
    gem 'simple-feed'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install simple-feed

### Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/kigster/simple-feed

### License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

### Acknowledgements

 * This project is conceived and sponsored by [Simbi, Inc.](https://simbi.com).
 * Author's personal experience at [Wanelo, Inc.](https://wanelo.com) has served as an inspiration.

 
