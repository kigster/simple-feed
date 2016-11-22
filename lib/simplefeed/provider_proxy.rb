require 'hashie/extensions/symbolize_keys'

module SimpleFeed
  class ProviderProxy
    attr_accessor :klass, :arguments, :provider

    def self.from(hash)
      Hashie::Extensions::SymbolizeKeys.symbolize_keys!(hash)
      self.new(hash[:klass], *hash[:args], **hash[:opts])
    end

    def initialize(klass, *args, **options)
      klass          = ::Object.const_get(klass) if klass.is_a?(::String)
      self.klass     = klass
      self.arguments = arguments

      self.provider  = klass.new(*args, **options)
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

