# frozen_string_literal: true

require_relative 'providers'
require_relative 'activity/base'
require 'simplefeed/key/template'

module SimpleFeed
  class Feed
    attr_accessor :per_page, :max_size, :batch_size, :meta, :namespace
    attr_reader :name

    SimpleFeed::Providers.define_provider_methods(self) do |feed, method, opts, &block|
      feed.provider.send(method, **opts, &block)
    end

    def initialize(name)
      @name         = name
      @name         = name.underscore.to_sym unless name.is_a?(Symbol)
      # set the defaults if not passed in
      @meta         = {}
      @namespace    = nil
      @per_page ||= 50
      @max_size ||= 1000
      @batch_size ||= 10
      @proxy = nil
    end

    def provider=(definition)
      @proxy      = Providers::Proxy.from(definition)
      @proxy.feed = self
      @proxy
    end

    def provider
      @proxy
    end

    def provider_type
      SimpleFeed::Providers::Base::Provider.class_to_registry(@proxy.provider.class)
    end

    def user_activity(user_id)
      Activity::SingleUser.new(user_id: user_id, feed: self)
    end

    def users_activity(user_ids)
      Activity::MultiUser.new(user_ids: user_ids, feed: self)
    end

    # Depending on the argument returns either +SingleUserActivity+ or +MultiUserActivity+
    def activity(one_or_more_users)
      one_or_more_users.is_a?(Array) ?
        users_activity(one_or_more_users) :
        user_activity(one_or_more_users)
    end

    def configure(hash = {})
      SimpleFeed.symbolize!(hash)
      class_attrs.each do |attr|
        send("#{attr}=", hash[attr]) if hash.key?(attr)
      end
      yield self if block_given?
    end

    def key(user_id)
      SimpleFeed::Providers::Key.new(user_id, key_template)
    end

    def eql?(other)
      other.class == self.class &&
        %i(per_page max_size name).all? { |m| send(m).equal?(other.send(m)) } &&
        provider.provider.class == other.provider.provider.class
    end

    def class_attrs
      SimpleFeed.class_attributes(self.class)
    end

    private

    def key_template
      SimpleFeed::Key::Template.new(namespace)
    end
  end
end
