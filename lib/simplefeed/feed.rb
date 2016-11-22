require_relative 'providers'
module SimpleFeed
  class Feed

    attr_accessor :per_page, :max_size
    attr_reader :name

    SimpleFeed::Providers::REQUIRED_METHODS.each do |m|
      define_method(m) do |*args, **opts, &block|
        self.provider.send(m, *args, **opts, &block)
      end
    end

    def initialize(name)
      @name     = name
      @name     = name.underscore.to_sym unless name.is_a?(Symbol)
      # set the defaults if not passed in
      @per_page ||= 50
      @max_size ||= 1000
      @proxy    = nil
    end

    def provider=(definition)
      @proxy = ProviderProxy.from(definition)
    end

    def provider
      @proxy
    end

    def configure(hash = {})
      SimpleFeed.symbolize!(hash)
      class_attrs.each do |attr|
        self.send("#{attr}=", hash[attr]) if hash.key?(attr)
      end
      yield self if block_given?
    end

    def equal?(other)
      other.class == self.class &&
        class_attrs.all? { |m| self.send(m).equal?(other.send(m)) }
    end

    def class_attrs
      SimpleFeed.class_attributes(self.class)
    end
  end
end
