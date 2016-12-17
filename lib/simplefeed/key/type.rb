require_relative 'template'

module SimpleFeed
  module Key
    class Type < Struct.new(:name, :marker)
      attr_accessor :template

      def initialize(name, marker, template = nil)
        super(name, marker)
        self.template = template
      end

      def render(opts = {})
        self.template.render(opts.merge({ 'key_type' => name, 'key_marker' => marker }))
      end
    end

    DEFAULT_TYPES = [
      { name: :data, marker: 'd' },
      { name: :meta, marker: 'm' }
    ].map do |type|
      Type.new(type[:name], type[:marker], DEFAULT_TEXT_TEMPLATE)
    end

  end
end
