
module SimpleFeed
  class Feed
    attr_accessor :name, :per_page, :max_size, :provider

    def initialize(name)
      @name     = name.underscore.to_sym unless name.is_a?(Symbol)
      # set the defaults if not passed in
      @per_page ||= 50
      @max_size ||= 1000
    end

    def configure
      yield self if block_given?
    end

    def equal?(other)
      other.class == self.class &&
        self.class.members.all? { |m| self.send(m).equal?(other.send(m)) }
    end
  end
end
