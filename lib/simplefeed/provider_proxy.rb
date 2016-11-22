module SimpleFeed
  class ProviderProxy
    attr_accessor :klass, :arguments

    def initialize(klass:, arguments: {})
      self.klass     = klass
      self.arguments = arguments

      if Kernel.const_defined?(klass)
      end
    end
  end
end

