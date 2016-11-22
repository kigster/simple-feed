require 'simplefeed/version'
require 'simplefeed/feed'

module SimpleFeed
  @registry = {}

  def self.registry
    @registry
  end

  def self.define(name, &block)
    name   = name.to_sym
    config = registry[name] ? registry[name] : SimpleFeed::Feed.new(name)
    config.instance_eval(&block)
    registry[name] = config
    config
  end

  def self.get(name)
    registry[name.to_sym]
  end
end
