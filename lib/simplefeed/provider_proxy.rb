module SimpleFeed
  class ProviderProxy
    attr_accessor :provider

    def self.from(definition)
      if definition.is_a?(Hash)
        ::SimpleFeed.symbolize!(definition)
        self.new(definition[:klass], *definition[:args], **definition[:opts])
      else
        self.new(definition)
      end

    end

    def initialize(provider_or_klass, *args, **options)
      if provider_or_klass.is_a?(::String)
        self.provider  = ::Object.const_get(provider_or_klass).new(*args, **options)
      else
        self.provider = provider_or_klass
      end

      SimpleFeed::Providers::REQUIRED_METHODS.each do |m|
        raise ArgumentError, "Invalid provider type #{provider.class} does not support required method #{m}" unless provider.respond_to?(m)
      end
    end

    # Forward all other method calls to Provider
    def method_missing(name, *args, &block)
      if self.provider && provider.respond_to?(name)
        self.provider.send(name, *args, &block)
      else
        super(name, *args, &block)
      end
    end
  end
end

