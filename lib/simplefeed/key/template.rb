require 'base62-rb'
require 'hashie/mash'

module SimpleFeed
  module Key

    class TextTemplate < Struct.new(:text)
      def render(params = {})
        output = self.text.dup
        params.each_pair do |key, value|
          output.gsub!(%r[{{\s*#{key}\s*}}], value.to_s)
        end
        output
      end
    end

    DEFAULT_TEXT_TEMPLATE = TextTemplate.new('{{ namespace }}u.{{ base62_user_id }}.{{ key_marker }}')

    class Template
      attr_accessor :namespace, :key_types, :text_template

      def initialize(namespace,
                     key_types = DEFAULT_TYPES,
                     text_template = DEFAULT_TEXT_TEMPLATE
      )

        self.namespace     = namespace
        self.key_types     = key_types
        self.text_template = text_template

        self.key_types.each do |type|
          type.template ||= text_template if text_template
        end
      end

      def render_options
        h = {}
        h.merge!({ 'namespace' => namespace ? "#{namespace}|" : '' })
        h
      end

      # Returns array of key names, such as [:meta, :data]
      def key_names
        key_types.map(&:name).map(&:to_s).sort
      end

      private

    end
  end
end

