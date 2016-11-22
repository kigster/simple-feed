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

Below we configure a feed called `:news_feed`, which presumably
will be populated with the events coming from the followers.

```ruby
require 'simplefeed'
require 'simplefeed/redis/provider'
require 'yaml'

# Let's configure backend provider via a Hash, although we can also
# instantiate it directly (as shown in the second example below)
provider_yaml = <<-eof
  klass: SimpleFeed::Redis::Provider
  opts:
    host: '127.0.0.1'
    port: 6379
    namespace: :fa 
    db: 1
eof

SimpleFeed.define(:news_feed) do |f|
  f.provider = YAML.load(provider_yaml) 
  f.max_size = 1000 # how many items can be in the feed
  f.per_page = 20 # default page size
end

# Now let's define another feed, by wrapping Redis connection
# in a +ConnectionPool+
SimpleFeed.feed(:notifications) do |f|
  f.provider = SimpleFeed::Redis::Provider.new(
    redis: -> { ::Redis.new(host: '192.168.10.10', port: 9000) },
    pool_size: 10
  )
  f.per_page = 50
end
```

After the feed is defined, the gem creates a similarly named method
under the `SimpleFeed` namespace to access the feed. For example, given
a name such as `:news_feed` the following are all valid ways of
accessing the feed:

 * `SimpleFeed.news_feed`
 * `SimpleFeed.get(:news_feed)`

You can also get a full list of currently defined feeds with `SimpleFeed.feed_names` method.

### Reading and Writing to the Feed for a given User

Each feed consists of many user activities, mapped by `user_id`. In
order to read and write to a feed of a given user, you need to obtain a
handle on a `UserActivity` instance for a given feed:

```ruby
@news_feed = SimpleFeed.news_feed
@user_activity = @news_feed.user_activity(current_user.id)

# A shorter alias for method #user_activity is #for
@user_activity = @news_feed.for(user_id)
````

#### Publishing Data to the Feed

Once we have an instance of the `UserActivity` class, we can use one of
the public methods to read and write into the feed:

```ruby
@user_activity.store(value: '{ "comment_id": 100, "author_id": 932424 }', at: Time.now)
@user_activity.store(value: 'Jon liked Christen\'s post', at: Time.now)
```
In the above example, we stored two separate events, one was stored as a `JSON` string, and the other as a human readable upate.

How exactly you serialize your events is up to you, but a higher-level
abstraction gem `activity-feed` decorates this library with additional
compact serialization schemes for ruby and Rails applications.

#### Reading the Feed

```ruby
require 'simplefeed'
  
@user_activity.unread_count
#=> 12
@user_activity.paginate(page: 1) 
# => [ 
# <SimpleFeed::Event#0x2134afa value='Jon followed Igbis' at='2016-11-20 23:32:56 -0800'>,
# <SimpleFeed::Event#0xf98f234 value='George liked Jons post' at='2016-12-10 21:32:56 -0800'>
# ....
# ]
# now, let's force-reset the last read timestamp
@user_activity.reset_last_read # defaults to Time.now
#=> 0
@user_activity.unread_count
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

 
