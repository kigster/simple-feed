# SimpleFeed — Scalable, easy to use activity feed implementation.

[![Gem Version](https://img.shields.io/gem/v/simple-feed.svg)](https://rubygems.org/gems/simple-feed)
[![MIT licensed](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/kigster/simple-feed/master/LICENSE.txt)

[![Build Status](https://travis-ci.org/kigster/simple-feed.svg?branch=master)](https://travis-ci.org/kigster/simple-feed)
[![Code Climate](https://codeclimate.com/repos/58339a5b3d9faa74ac006b36/badges/8b899f6df4fc1ed93759/gpa.svg)](https://codeclimate.com/repos/58339a5b3d9faa74ac006b36/feed)
[![Test Coverage](https://codeclimate.com/repos/58339a5b3d9faa74ac006b36/badges/8b899f6df4fc1ed93759/coverage.svg)](https://codeclimate.com/repos/58339a5b3d9faa74ac006b36/coverage)
[![Issue Count](https://codeclimate.com/repos/58339a5b3d9faa74ac006b36/badges/8b899f6df4fc1ed93759/issue_count.svg)](https://codeclimate.com/repos/58339a5b3d9faa74ac006b36/feed)
[![Inline docs](http://inch-ci.org/github/kigster/simple-feed.svg?branch=master)](http://inch-ci.org/github/kigster/simple-feed)
[![Talk on Gitter](https://img.shields.io/gitter/room/gitterHQ/gitter.svg)](https://gitter.im/kigster/simple-feed)

> Please read the blog post [Feeding Frenzy with SimpleFeed](http://kig.re/2017/02/19/feeding-frenzy-with-simple-feed-activity-feed-ruby-gem.html) launching this library. Please leave comments or questions in the discussion thread at the bottom of that post. Thanks! 

If you like to see this project grow, your donation of any amount is much appreciated.

[![Donate](https://www.paypalobjects.com/en_US/i/btn/btn_donate_SM.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=FSFYYNEQ8RKWU)

---

This is a fast, pure-ruby implementation of an activity feed concept commonly used in social networking applications. The implementation is optimized for **read-time performance** and high concurrency (lots of users), and can be extended with custom backend providers. Two providers come bundled: the production-ready Redis provider, and a naive Ruby Hash-based provider.

__Important Notes and Acknowledgements:__

 * SimpleFeed *does not depend on Ruby on Rails* and is a __pure-ruby__ implementation
 * SimpleFeed requires ruby 2.3 or later
 * SimpleFeed is currently live in production
 * SimpleFeed is open source thanks to the generosity of __[Simbi, Inc](http://simbi.com)__.

## Background, Examples, Serialization, etc

Please read the additional documentation, including the examples, on the [project's Github Wiki](https://github.com/kigster/simple-feed/wiki).

Below is a screen shot of an actual activity feed powered by this library.

![usage](https://raw.githubusercontent.com/kigster/simple-feed/master/man/activity-feed-action.png)

## Usage

A key concept to understanding SimpleFeed gem, is that of a _provider_, which is effectively a persistence implementation for the events belonging to each user.

Two providers are supplied with this gem:

 * The production-ready `:redis` provider, which uses the [sorted set Redis data type](https://redislabs.com/ebook/redis-in-action/part-2-core-concepts-2/chapter-3-commands-in-redis/3-5-sorted-sets) to store and fetch the events, scored by time (but not necessarily). 

 * The naïve `:hash` provider based on the ruby `Hash` class, that can be useful in unit tests, or in simple simulations. 

You initialize a provider by using the `SimpleFeed.provider([Symbol])` method.

### Configuration

Below we configure a feed called `:newsfeed`, which in this example will be populated with the various events coming from the followers. 

```ruby
require 'simplefeed'

# Let's define a Redis-based feed, and wrap Redis in a in a ConnectionPool. 
SimpleFeed.define(:newsfeed) do |f|
  f.provider   = SimpleFeed.provider(:redis, 
                                      redis: -> { ::Redis.new },
                                      pool_size: 10)
  f.per_page   = 50     # default page size
  f.batch_size = 10     # default batch size
  f.namespace  = 'nf'   # only needed if you use the same redis for more than one feed
end
```

After the feed is defined, the gem creates a similarly named method under the `SimpleFeed` namespace to access the feed. For example, given a name such as `:newsfeed` the following are all valid ways of accessing the feed:

 * `SimpleFeed.newsfeed`
 * `SimpleFeed.get(:newsfeed)`

You can also get a full list of currently defined feeds with `SimpleFeed.feed_names` method.

### Reading from and writing to the feed

For the impatient, here is a quick way to get started with the `SimpleFeed`.

```ruby
# This assumes we have previously defined a feed named :newsfeed (see above)
activity = SimpleFeed.newsfeed.activity(@current_user.id)
# Store directly the value and the optional time stamp
activity.store(value: 'hello')
# => true

# or equivalent:
@event = SimpleFeed::Event.new('hello', Time.now)
activity.store(event: @event)
# => false # false indicates that the same event is already in the feed.
```

As we've added events for this user, we can request them back, sorted by
the time and paginated. If you are using a distributed provider, such as
`Redis`, the events can be retrieved by any ruby process in your
application, not just the one that published the event (which is the
case for the "toy" `Hash::Provider`.

```ruby
activity.paginate(page: 1, reset_last_read: true)
# => [ <SimpleFeed::Event#0x2134afa value='hello' at='2016-11-20 23:32:56 -0800'> ]
```

### The Two Forms of the API

The feed API is offered in two forms:

 1. single-user form, and 
 2. a batch (multi-user) form.

The method names and signatures are the same. The only difference is in what the methods return:

 1. In the single user case, the return of, say, `#total_count` is an `Integer` value representing the total count for this user.
 2. In the multi-user case, the return is a `SimpleFeed::Response` instance, that can be thought of as a `Hash`, that has the user IDs as the keys, and return results for each user as a value. 

Please see further below the details about the [Batch API](#batch-api).

<a name="single-user-api"/>

##### Single-User API 

In the examples below we show responses based on a single-user usage. As previously mentioned, the multi-user usage is the same, except what the response values are, and is discussed further down below.

Let's take a look at a ruby session, which demonstrates return values of the feed operations for a single user:

```ruby
require 'simplefeed'

# Define the feed using an in-memory Hash provider, which uses
# SortedSet to keep user's events sorted.
SimpleFeed.define(:followers) do |f|
  f.provider = SimpleFeed.provider(:hash)
  f.per_page = 50
  f.per_page = 2
end

# Let's get the Activity instance that wraps this user_id
activity = SimpleFeed.followers.activity(user_id)   # => [... complex object removed for brevity ]
# let's clear out this feed to ensure it's empty
activity.wipe                                             # => true
# Let's verify that the counts for this feed are at zero
activity.total_count                                      # => 0
activity.unread_count                                     # => 0
# Store some events
activity.store(value: 'hello')                            # => true
activity.store(value: 'goodbye', at: Time.now - 20)       # => true
activity.unread_count                                     # => 2
# Now we can paginate the events, while resetting this user's last-read timestamp:
activity.paginate(page: 1, reset_last_read: true)
# [
#     [0] #<SimpleFeed::Event: value=good bye, at=1480475294.0579991>,
#     [1] #<SimpleFeed::Event: value=hello, at=1480475294.057138>
# ]
# Now the unread_count should return 0 since the user just "viewed" the feed.
activity.unread_count                                     # => 0
activity.delete(value: 'hello')                           # => true
# the next method yields to a passed in block for each event in the user's feed, and deletes
# all events for which the block returns true. The return of this call is the
# array of all events that have been deleted for this user.
activity.delete_if do |event, user_id|
  event.value =~ /good/
end                                                       
# => [
#     [0] #<SimpleFeed::Event: value=good bye, at=1480475294.0579991>
# ]   
activity.total_count                                      # => 0
```

You can fetch all items (optionally filtered by time) in the feed using `#fetch`, 
`#paginate` and reset the `last_read` timestamp by passing the `reset_last_read: true` as a parameter.

<a name="batch-api"/>

#####  Batch (Multi-User) API 

This API should be used when dealing with an array of users (or, in the
future, a Proc or an ActiveRecord relation). 

> There are several reasons why this API should be preferred for
> operations that perform a similar action across a range of users:
> _various provider implementations can be heavily optimized for
> concurrency, and performance_.
> 
> The Redis Provider, for example, uses a notion of `pipelining` to send
> updates for different users asynchronously and concurrently.

Multi-user operations return a `SimpleFeed::Response` object, which can
be used as a hash (keyed on user_id) to fetch the result of a given
user.

```ruby
# Using the Feed API with, eg #find_in_batches
@event_producer.followers.find_in_batches do |group|
 
  # Convert a group to the array of IDs and get ready to store
  activity = SimpleFeed.get(:followers).activity(group.map(&:id))
  activity.store(value: "#{@event_producer.name} liked an article")
  
  # => [Response] { user_id1 => [Boolean], user_id2 => [Boolean]... } 
  # true if the value was stored, false if it wasn't.
end
```

##### Activity Feed DSL (Domain-Specific Language) 

The library offers a convenient DSL for adding feed functionality into
your current scope.

To use the module, just include `SimpleFeed::DSL` where needed, which
exports just one primary method `#with_activity`. You call this method
and pass an activity object created for a set of users (or a single
user), like so:

```ruby
require 'simplefeed/dsl'
include SimpleFeed::DSL

feed = SimpleFeed.newsfeed
activity = feed.activity(current_user.id)
data_to_store = %w(France Germany England)

def report(value)
  puts value
end

with_activity(activity, countries: data_to_store) do
  # we can use countries as a variable because it was passed above in **opts
  countries.each do |country|
    # we can call #store without a receiver because the block is passed to 
    # instance_eval
    store(value: country) { |result| report(result ? 'success' : 'failure') }
    # we can call #report inside the proc because it is evaluated in the 
    # outside context of the #with_activity
    
    # now let's print a color ASCII dump of the entire feed for this user: 
    color_dump 
  end  
  printf "Activity counts are: %d unread of %d total\n", unread_count, total_count
end
```

The DSL context has access to two additional methods: 

 * `#event(value, at)` returns a fully constructed `SimpleFeed::Event` instance
 * `#color_dump` prints to STDOUT the ASCII text dump of the current user's activities (events), as well as the counts and the `last_read` shown visually on the time line.
 
##### `#color_dump`

Below is an example output of `color_dump` method, which is intended for the debugging purposes.

[<img src="https://raw.githubusercontent.com/kigster/simple-feed/master/man/sf-color-dump.png" width="450" alt="color_dump output" style="width: 300px; max-width:100%;">](https://raw.githubusercontent.com/kigster/simple-feed/master/man/sf-color-dump.png)

<a name="api"/>

## Complete API

For completeness sake we'll show the multi-user API responses only. For a single-user use-case the response is typically a scalar, and the input is a singular `user_id`, not an array of ids. 

#### Multi-User (Batch) API

Each API call at this level expects an array of user IDs, therefore the
return value is an object, `SimpleFeed::Response`, containing individual
responses for each user, accessible via `response[user_id]` method.

```ruby
@multi = SimpleFeed.get(:feed_name).activity(User.active.map(&:id))

@multi.store(value:, at:)
@multi.store(event:)
# => [Response] { user_id => [Boolean], ... } true if the value was stored, false if it wasn't.

@multi.delete(value:, at:)
@multi.delete(event:)
# => [Response] { user_id => [Boolean], ... } true if the value was removed, false if it didn't exist

@multi.delete_if do |event, user_id|
  # if the block returns true, the event is deleted and returned 
end
# => [Response] { user_id => [deleted_event1, deleted_event2, ...], ... }

# Wipe the feed for a given user(s)
@multi.wipe
# => [Response] { user_id => [Boolean], ... } true if user activity was found and deleted, false otherwise

# Return a paginated list of all items, optionally with the total count of items
@multi.paginate(page: 1, 
                per_page: @multi.feed.per_page, 
                with_total: false, 
                reset_last_read: false)
# => [Response] { user_id => [Array]<Event>, ... }
# Options:
#   reset_last_read: false — reset last read to Time.now (true), or the provided timestamp
#   with_total: true — returns a hash for each user_id:
#        => [Response] { user_id => { events: Array<Event>, total_count: 3 }, ... } 

# Return un-paginated list of all items, optionally filtered
@multi.fetch(since: nil, reset_last_read: false)
# => [Response] { user_id => [Array]<Event>, ... }
# Options:
#   reset_last_read: false — reset last read to Time.now (true), or the provided timestamp
#   since: <timestamp> — if provided, returns all items posted since then
#   since: :last_read — if provided, returns all unread items and resets +last_read+

@multi.reset_last_read
# => [Response] { user_id => [Time] last_read, ... }

@multi.total_count
# => [Response] { user_id => [Integer] total_count, ... }

@multi.unread_count
# => [Response] { user_id => [Integer] unread_count, ... }

@multi.last_read
# => [Response] { user_id => [Time] last_read, ... }

```

## Providers in Depth 

As we've discussed above, a provider is an underlying persistence mechanism implementation. 

It is the intention of this gem that:

 * it should be easy to write new providers 
 * it should be easy to swap out providers

To create a new provider please use `SimpleFeed::Providers::Hash::Provider` class as a starting point.

Two providers are available with this gem:

### `SimpleFeed::Providers::Redis::Provider` 

Redis Provider is a production-ready persistence adapter that uses the [sorted set Redis data type](https://redislabs.com/ebook/redis-in-action/part-2-core-concepts-2/chapter-3-commands-in-redis/3-5-sorted-sets). 

This provider is optimized for large writes and can use either a single Redis instance for all users of your application, or any number of Redis [shards](https://en.wikipedia.org/wiki/Shard_(database_architecture)) by using a [_Twemproxy_](https://github.com/twitter/twemproxy) in front of the Redis shards. 

### `SimpleFeed::Providers::HashProvider`
 
This is a pure Hash-like implementation of a provider that can be useful in unit tests of a host application. This provider could be used to write and read events within a single ruby process, can be serialized to and from a YAML file, and is therefore intended primarily for Feed emulations in automated tests.
  
## Redis Provider

If you set environment variable `REDIS_DEBUG` to `true` and run the example (see below) you will see every operation redis performs. This could be useful in debugging an issue or submitting a bug report.
  
## Running the Examples

Source code for the gem contains the `examples` folder with an example file that can be used to test out the providers, and see what they do under the hood.

To run it, checkout the source of the library, and then:

```bash
git clone https://github.com/kigster/simple-feed.git
cd simple-feed
bundle
be rspec  # make sure tests are passing
ruby examples/redis_provider_example.rb 
```

The above command will help you download, setup all dependencies, and run the examples for a single user: 

[![Example](https://raw.githubusercontent.com/kigster/simple-feed/master/man/running-example.png)](https://raw.githubusercontent.com/kigster/simple-feed/master/man/running-example.png)

If you set `REDIS_DEBUG` variable prior to running the example, you will be able to see every single Redis command executed as the example works its way through. Below is a sample output:

[![Example with Debugging](https://raw.githubusercontent.com/kigster/simple-feed/master/man/running-example-redis-debug.png)](https://raw.githubusercontent.com/kigster/simple-feed/master/man/running-example-redis-debug.png)

### Generating Ruby API Documentation

```bash
rake doc
```

This should use Yard to generate the documentation, and open your browser once it's finished.

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


