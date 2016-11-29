
module SimpleFeed
  module Providers
    module Base

      class ProviderMethodNotImplementedError < StandardError
        def initialize(method)
          super("Method #{method} from #{self.class} went to BaseProvider, because no single-user version was defined (#{method}_1u), nor a sub-class override.")
        end
      end

    end
  end
end
