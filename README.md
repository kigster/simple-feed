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
  klass: SimpleFeed::Providers::Redis::Provider
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
# in a ConnectionPool
SimpleFeed.define(:notifications) do |f|
  f.provider = SimpleFeed::Providers::Redis::Provider.new(
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

Each feed consists of many user activities, mapped by `user_ids`. In
order to read and write to a feed of a given user, you need to obtain a
handle on a `SimpleFeed::UserActivity` instance for a given feed:

```ruby
@news_feed = SimpleFeed.news_feed
@user_activity = @news_feed.user_activity(current_user.id)

# A shorter alias for method #user_activity is #for
@user_activity = @news_feed.for(user_id)
````

#### Two Versions of the API

The API is offered in two approaches:

1. Single-user API is accessed via the `SimpleFeed::Feed#user_activity` instance method.
   Optimized for simplicity of data retrieval of a single-user,
   this method allows performing multiple queries about the same
   user in an optimized fashion sometimes avoiding unnecessary requests.

2. Multi-user API is accessed via methods on the `SimpleFeed::Feed` instance.
   This API is recommended when dealing with updates of activity feed belonging to many users at
   the same time.
    * The Redis Provider, for example, uses `pipelining` to send updates
      for different users asynchronously and concurrently.
    * Multi-user operations return a `SimpleFeed::Response` object,
      which can be used as a hash (keyed on user_id) to fetch the result
      of a given user.


#### Publishing Data to the Feed

Once we have an instance of the `UserActivity` class, we can use one of
the public methods to read and write into the feed:

```ruby
# Using the Feed API:
SimpleFeed.get(:followers).store(user_ids: [1,2,3...], value: 'hello', at: Time.now)

# Using UserActivity API:
user_activity = SimpleFeed.get(:followers).user_activity(current_user.id)
user_activity.store(value: '{ "comment_id": 100, "author_id": 932424 }', at: Time.now)
user_activity.store(value: 'Jon liked Christen\'s post', at: Time.now)
```
In the above example, we stored two separate events, one was stored as a `JSON` string, and the other as a human readable upate.

How exactly you serialize your events is up to you, but a higher-level
abstraction gem `activity-feed` decorates this library with additional
compact serialization schemes for ruby and Rails applications.

#### Reading the Feed

```ruby
require 'simplefeed'

user_activity.total_count
#=> 412 
user_activity.unread_count
#=> 12
user_activity.paginate(page: 1) 
# => [ 
# <SimpleFeed::Event#0x2134afa value='Jon followed Igbis' at='2016-11-20 23:32:56 -0800'>,
# <SimpleFeed::Event#0xf98f234 value='George liked Jons post' at='2016-12-10 21:32:56 -0800'>
# ....
# ]
# now, let's force-reset the last read timestamp
user_activity.reset_last_read # defaults to Time.now
#=> 0
user_activity.unread_count
#=> 0
```

### API & Usage 

Below is the complete set of API methods that can be called on either
the `Feed` class directly (while providing an array of user_ids), for
example:

```ruby
SimpleFeed.get(:news).store(user_ids: [1,2,....], value: '123', at: Time.now)
```

Or, for a single user, via the `UserActivity` convenience class:

```ruby
@ua = SimpleFeed.get(:news).user_activity(1)
@ua.store(value: '123', at: Time.now)
@ua.total_count
#=> 342
@ua.unread_count
#=> 4

puts @ua.all.inspect
```

#### Single User API

`UserActivity` class:

```ruby
@ua = SimpleFeed.get(:feed_name).user_activity(1)

@ua.store(value:, at:)
# => true if the value was stored, false if it wasn't.
@ua.remove(value:, at:)
# => true if the value was removed, false if it didn't exist
@ua.wipe
# => true
@ua.paginate(page:, per_page:, peek: true|false)
# => Array[ event, event, ...]
@ua.all
# => Array[ event, event, ...]
@ua.reset_last_read
# => last read
@ua.total_count
# => Integer count
@ua.unread_count
# => Integer count
@ua.last_read
# => Time last_read
```

#### Batch User API

Each API call at this level expects an array of user IDs, therefore the
return value is an object, `SimpleFeed::Response`, containing individual
responses for each user, accessible via `response[user_id]` method.

```ruby
SimpleFeed.get(:feed_name).instance_eval do 
  
  store(user_ids:, value:, at:)          # Store an event for a user
  
  remove(user_ids:, value:, at: nil)     # Remove an event for a user
  
  wipe(user_ids:)                        # Wipe the user's feed

  paginate(user_ids:,                    # Paginate events for the user, 
               page:,                    # when peek: true is provided,
           per_page:,                    # do not reset #last_read, 
               peek:)                    # but otherwise reset it
                                                           
  
  all(user_ids:)                         # Return ALL events for the user

  total_count(user_ids:)                 # Total event count for the user
  unread_count(user_ids:)                # Unread count

  last_read(user_ids:)                   # Returns time when the feed was 
                                         # read last
                                        
  reset_last_read(user_ids:)             # Reset last read timestamp for the user
                                         # (also should reset #unread_count)
end
```

## Providers

A provider is an underlying implementation that persists the events for each user, together with some meta-data for each feed.

It is the intention of this gem that:

 * it should be easy to swap providers
 * it should be easy to add new providers

Each provider must implement exactly the public API of a provider shown
above (the `Feed` version, that receives `user_ids:` as arguments).

Two providers are available with this gem:

 * `SimpleFeed::Providers::Redis::Provider` is the production-ready provider that uses ZSET operations to store events as a sorted set in Redis
* `SimpleFeed::Providers::HashProvider` is the pure Hash implementation
  of a provider that can be useful in unit tests of the host
  application. This provider may be used to push events within a single
  ruby process, but can be serialized to a YAML file in order to be
  restored later in another process.

### Installation

Add this line to your application's Gemfile:

```ruby
gem 'simple-feed'
```

And then execute:

```
$ bundle
```

Or install it yourself as:

```
$ gem install simple-feed
```

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

 
